#include "PCH.h"

#include <array>
#include <atomic>
#include <cstdint>
#include <memory>

namespace
{
    // These are stop/reset event names used for silent cleanup. The uploaded PEX
    // definitely contains the "staggerStop" animation-event string; "IdleStop"
    // is used by the script as its idle-stop property and is also a common graph
    // stop event. Intentionally do NOT start the Taunt/Rebreath/attack idles.
    constexpr std::array<const char*, 2> kSilentResetEvents{
        "staggerStop",
        "IdleStop"
    };

    constexpr std::uint32_t kMaxReadyRetries = 120;

    // One repair per kPostLoadGame. kPreLoadGame resets the guard for the next load.
    std::atomic_bool g_repairQueued{ false };
    std::atomic_bool g_repairedThisLoad{ false };

    void QueueRepairAttempt(std::uint32_t attempt);

    void RepairPlayer(RE::PlayerCharacter* player)
    {
        if (!player) {
            SKSE::log::warn("RepairPlayer: player singleton is null");
            return;
        }

        std::uint32_t sentCount = 0;
        for (const auto* eventName : kSilentResetEvents) {
            const bool sent = player->NotifyAnimationGraph(RE::BSFixedString(eventName));
            SKSE::log::info("Sent animation graph reset event '{}' (accepted={})", eventName, sent);
            sentCount += sent ? 1U : 0U;
        }

        SKSE::log::info("Silent player-state repair finished; {} of {} events accepted",
            sentCount, kSilentResetEvents.size());
    }

    void QueueRepairAttempt(std::uint32_t attempt)
    {
        const auto* taskInterface = SKSE::GetTaskInterface();
        if (!taskInterface) {
            SKSE::log::error("SKSE task interface unavailable; cannot queue player repair");
            g_repairQueued.store(false);
            return;
        }

        taskInterface->AddTask([attempt]() {
            if (g_repairedThisLoad.load()) {
                return;
            }

            auto* player = RE::PlayerCharacter::GetSingleton();
            RE::BSTSmartPointer<RE::BSAnimationGraphManager> graphManager;
            const bool graphReady = player && player->Get3D() &&
                player->GetAnimationGraphManagerImpl(graphManager) && graphManager;

            if (!graphReady) {
                if (attempt < kMaxReadyRetries) {
                    QueueRepairAttempt(attempt + 1);
                } else {
                    SKSE::log::warn(
                        "Player animation graph did not become ready after {} retries; skipping this load",
                        kMaxReadyRetries);
                    g_repairQueued.store(false);
                }
                return;
            }

            bool expected = false;
            if (!g_repairedThisLoad.compare_exchange_strong(expected, true)) {
                return;
            }

            SKSE::log::info("Player ready after save load; applying silent state repair once");
            RepairPlayer(player);
        });
    }

    void OnSKSEMessage(SKSE::MessagingInterface::Message* message)
    {
        if (!message) {
            return;
        }

        switch (message->type) {
        case SKSE::MessagingInterface::kPreLoadGame:
            g_repairQueued.store(false);
            g_repairedThisLoad.store(false);
            SKSE::log::info("Save load started; repair guard reset");
            break;

        case SKSE::MessagingInterface::kPostLoadGame: {
            bool expected = false;
            if (g_repairQueued.compare_exchange_strong(expected, true)) {
                SKSE::log::info("Save load completed; queueing one silent player-state repair");
                QueueRepairAttempt(0);
            } else {
                SKSE::log::debug("Ignoring duplicate post-load message for current load");
            }
            break;
        }

        default:
            break;
        }
    }

    void InitializeLogging()
    {
        try {
            const auto logDirectory = SKSE::log::log_directory();
            if (!logDirectory) {
                return;
            }

            const auto logPath = *logDirectory / "RebreathStateRepair.log";
            auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(logPath.string(), true);
            auto logger = std::make_shared<spdlog::logger>("RebreathStateRepair", std::move(sink));
            spdlog::set_default_logger(std::move(logger));
            spdlog::set_level(spdlog::level::info);
            spdlog::flush_on(spdlog::level::info);
        } catch (...) {
            // Logging must never prevent the plugin from loading.
        }
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    SKSE::Init(skse);
    InitializeLogging();

    SKSE::log::info("RebreathStateRepair loaded");

    const auto messaging = SKSE::GetMessagingInterface();
    if (!messaging || !messaging->RegisterListener("SKSE", OnSKSEMessage)) {
        SKSE::log::critical("Failed to register SKSE messaging listener");
        return false;
    }

    SKSE::log::info("Listening for kPreLoadGame / kPostLoadGame");
    return true;
}
