using System;
using System.IO;
using System.Linq;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;

if (args.Length != 1)
{
    Console.Error.WriteLine("Usage: PluginBuilder <staging-root>");
    return 2;
}

string root = Path.GetFullPath(args[0]);
string dataDir = Path.Combine(root, "Data");
string seqDir = Path.Combine(dataDir, "Seq");
Directory.CreateDirectory(dataDir);
Directory.CreateDirectory(seqDir);

ModKey pluginKey = ModKey.FromFileName("RebreathAutoRepair.esp");
ModKey skyrimKey = ModKey.FromFileName("Skyrim.esm");
FormKey playerRefKey = new FormKey(skyrimKey, 0x00000014);

var mod = new SkyrimMod(pluginKey, SkyrimRelease.SkyrimSE);
mod.ModHeader.MasterReferences.Add(new MasterReference { Master = skyrimKey });

var quest = mod.Quests.AddNew("RebreathAutoRepairQuest");
quest.Name = "Rebreath Auto Repair";
quest.Priority = 60;
quest.Flags |= Quest.Flag.StartGameEnabled;
quest.NextAliasID = 1;

var playerAlias = new QuestAlias
{
    ID = 0,
    Type = QuestAlias.TypeEnum.Reference,
    Name = "PlayerAlias"
};
playerAlias.ForcedReference.SetTo(playerRefKey);
quest.Aliases.Add(playerAlias);

var adapter = new QuestAdapter();
var fragmentAlias = new QuestFragmentAlias
{
    Property = new ScriptObjectProperty
    {
        Object = quest.FormKey.ToLink<ISkyrimMajorRecordGetter>(),
        Alias = 0,
        Flags = ScriptProperty.Flag.Edited
    }
};
fragmentAlias.Scripts.Add(new ScriptEntry
{
    Name = "RebreathAutoRepairAlias",
    Flags = ScriptEntry.Flag.Local
});
adapter.Aliases.Add(fragmentAlias);
quest.VirtualMachineAdapter = adapter;

string espPath = Path.Combine(dataDir, "RebreathAutoRepair.esp");
mod.WriteToBinary(espPath);

// SEQ is a little-endian list of plugin-relative FormIDs for Start Game Enabled quests.
// The plugin builder allocates the QUST FormID; serialize its local ID exactly.
string seqPath = Path.Combine(seqDir, "RebreathAutoRepair.seq");
using (var stream = File.Create(seqPath))
using (var writer = new BinaryWriter(stream))
{
    writer.Write(quest.FormKey.ID);
}

// Read the plugin back through Mutagen and fail the build if any critical wiring is missing.
using var reloaded = SkyrimMod.CreateFromBinaryOverlay(espPath, SkyrimRelease.SkyrimSE);
var quests = reloaded.Quests.ToList();
if (quests.Count != 1)
    throw new InvalidDataException($"Expected exactly one QUST, got {quests.Count}.");

var loadedQuest = quests[0];
if (!loadedQuest.Flags.HasFlag(Quest.Flag.StartGameEnabled))
    throw new InvalidDataException("Quest is not Start Game Enabled.");

var loadedAlias = loadedQuest.Aliases.SingleOrDefault(a => a.Name == "PlayerAlias")
    ?? throw new InvalidDataException("PlayerAlias was not written.");
if (loadedAlias.Type != QuestAlias.TypeEnum.Reference)
    throw new InvalidDataException("PlayerAlias is not a Reference Alias.");
if (loadedAlias.ForcedReference.FormKey != playerRefKey)
    throw new InvalidDataException($"PlayerAlias does not point to Skyrim.esm:00000014; got {loadedAlias.ForcedReference.FormKey}.");

if (loadedQuest.VirtualMachineAdapter is not QuestAdapter loadedAdapter)
    throw new InvalidDataException("Quest VMAD is missing or is not QuestAdapter.");

var loadedFragment = loadedAdapter.Aliases.SingleOrDefault(a => a.Property?.Alias == 0)
    ?? throw new InvalidDataException("Quest VMAD does not contain the PlayerAlias script binding.");
if (!loadedFragment.Scripts.Any(s => s.Name == "RebreathAutoRepairAlias"))
    throw new InvalidDataException("RebreathAutoRepairAlias script entry is missing.");

byte[] seq = File.ReadAllBytes(seqPath);
if (seq.Length != 4 || BitConverter.ToUInt32(seq, 0) != loadedQuest.FormKey.ID)
    throw new InvalidDataException("SEQ file does not contain the generated quest's local FormID.");

Console.WriteLine($"ESP verified: {espPath}");
Console.WriteLine($"Quest FormID (local): 0x{loadedQuest.FormKey.ID:X6}");
Console.WriteLine("Quest: Start Game Enabled");
Console.WriteLine("Alias: PlayerAlias -> Skyrim.esm:00000014");
Console.WriteLine("VMAD: RebreathAutoRepairAlias attached to alias 0");
Console.WriteLine($"SEQ verified: {seqPath}");
return 0;
