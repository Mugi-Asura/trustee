# trustee
Trustee is a Trust management addon for Ashita (FFXI). It allows users to create sets of Trusts which can be summoned via a command line interface. This was created to help me learn a bit about Lua as a side project.

The addon takes lists of Trust character names with somewhat loose input rules and provides a simple interface for summoning entire parties of Trusts without the need for lots of script files or macros. Each set can be named and they're all stored by the addon itself in JSON files, meaning you end up with a small database of Trust summoning instructions. When a Trust set is summoned, the addon pulls the relevant Trust set from the database, creates a new script file to hold the summoning instructions, then executes the script. 

I haven't picked a license for this addon yet. I'll figure it out when I'm done updating the code.

Note: If the Ashita functionality is expanded in the future (and I'm still playing FFXI; I play in phases) I'll update this addon to support in-memory script execution rather than dynamically creating scripts and running them from the settings folder.

Note 2: I got the list of Trust names from FFXI Encyclopedia, so it may be missing some. I don't personally have anywhere near all the Trusts, but if it's missing any just let me know and I'll add it to the names database for everyone to enjoy.

**Note 3: I do play on Asura, but my name is not Mugi. I don't know how much Square cares about Windower/Ashita these days so I picked another handle to avoid a potential ban. If there's a person on Asura named Mugi, I'm sorry ahead of time if people are messaging you about some obscure FFXI addon.**

## Updates

**v1.1.1**: Change: Updated the name map to better support gathering Trust names from the party list when using "/trustee add SetName party".

**v1.1.0**: New feature: Generate Trust sets from your current party list (with restrictions: see "add" help information). Fix: Updated the help information to mention case sensitive inputs.

**v1.0.1**: Bugfix: in some cases with a full party, Trusts would not un-summon fast enough for the next party. Increased the un-summon buffer time to 4 seconds.

**v1.0.0**: Initial commit.

### Potential Future Updates

1. **Fix the command function code.** It's quite monolithic right now. I started breaking things down into functions, but decided to post this functional version as a starting point.
2. **Add some colours to the addon output.** It's currently all white and that makes it difficult/annoying to read. I'll probably colour-code different labels and outputs to make it easier to know when the addon is pushing information to the user.
3. **Better (any) algorithmic efficiency.** I mostly coded things that worked rather than things that were fast. However, it's FFXI and I doubt the game is stressing anyone's computer enough that my O(n<sup>2</sup>) search algorithms over ~200 elements are destroying their performance.


## Installation and Commands
The addon can be loaded into Ashita by placing the files (trustee.lua and settings directory) into ./Ashita/addons/trustee and running the "/addon load trustee" command from the Final Fantasy XI chat bar or via a script file (such as the Ashita startup script). 

The available commands are as follows:

### Add Trust Set Command:

**Syntax:** */trustee add SetName TrustList*
**Syntax:** */trustee add SetName party*

This command creates a new Trust set which may be summoned later using "/tr SetName". SetName can be any character string and uniquely identifies the registered set. If SetName is already a set name, it will be overwritten. Note that SetNames are case sensitive.
TrustList is a comma-separated list of Trust names which will be included in the set named SetName. Capitalization does not matter. Any spaces included in the TrustList will be removed. 

For a list of shorthand names available for a given Trust (to include in a TrustList), please use the command "/tr char TrustName", where TrustName is the Trust\'s full name from the in-game Trust menu.

The following examples all create differently named sets with the exact same Trust characters:
```
/trustee add set1 Apururu (UC), Semih Lafihna, Trion
/tr add set2 apururu,semih, Trion
/tr add set3 Apururu,semih,trion
/tr add set4 aPuRuRu,Semih Lafihna, TRION
```

Rather than including a list of Trusts, you may use the "party" keyword. This will create a Trust set containing the Trusts which are currently present in your party. 

**Note that this is incompatible with alternate versions of Trusts (such as Lion vs. Lion II) because the game does not differentiate those Trusts once they\'re in your party. For example, after summoning Lion II, her name will appear as Lion in the party list and thus Trustee will only save their default name (Lion, not Lion II) in the Trust set.**

### Remove Trust Set Command:
 
**Syntax:** */trustee remove SetName*

SetName can be any character string and uniquely identifies the registered set. If SetName references a set in the trust set database, the associated Trust set will be removed. Otherwise this command will do nothing except show an alert message. Note that SetNames are case sensitive.

### Verbose Toggle Command:
 
**Syntax:** */trustee verbose on/off*

Toggles verbose mode on or off, depending on which command you use. While turned on, verbose mode will generate more messages about subsequent commands as they are entered.

### Backup Commands:
 
**Syntax:** */trustee backup*

Initiates an immediate backup of the Trust set database. Backups are found in the addon settings folder.
 
**Syntax:** */trustee backup on/off*

Toggles automatic backups on or off, depending on which command you use. While turned on, the Trustee
	 addon will perform an automatic backup of the pre-load Trust set database. See above for backup location.

### Summon Trust Set Command:
 
**Syntax:** */trustee SetName*

This command summons the Trust set uniquely identified by the SetName value. If the SetName value is not found in the Trust set database, no Trust set will be summoned. Note that SetNames are case sensitive.

The summoning process uses regular macro-style wait commands to ensure proper Trust cast timing.

The length of time required to summon a Trust set is based on size and takes the following times:
```   
1 Trust  = 10  seconds
2 Trusts = 16 seconds
3 Trusts = 22 seconds
4 Trusts = 28 seconds
5 Trusts = 34 seconds
```
### List Trust Sets Command:
 
**Syntax:** */trustee list*

This command shows all stored Trust sets in a numbered list in the format of *SetName -> TrustList*.

### Trust Character Shorthand Names Command:
 
**Syntax:** */trustee char TrustName*

This command will show the possible shorthand names for the Trust character\'s name entered. When entering names into the TrustList in a "/tr add" command, you may use a Trust\'s full name or one of the available shorthand names provided by this command.
