--------------------------------------------------------------
-- Addon Metadata
--------------------------------------------------------------
_addon.author   = 'Mugi';
_addon.name     = 'Trustee';
_addon.version  = '1.1.0';

--------------------------------------------------------------
-- Load Required Libraries
--------------------------------------------------------------
require 'common'

--------------------------------------------------------------
-- Initialize default addon class variables
--------------------------------------------------------------
local addonSettings = { };

--------------------------------------------------------------
-- Create a table for holding the trust lists
--------------------------------------------------------------
local trustList = { };

--------------------------------------------------------------
-- Create a table for holding the cipher names
--------------------------------------------------------------
local nameList = { };

--------------------------------------------------------------
-- Create a variable for holding the current file pointer
--------------------------------------------------------------
local scriptFile = nil;

--------------------------------------------------------------
-- Load Function: 
-- Called when the addon is being loaded. Also called after
-- the unload function when a reload command is entered.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function loadFunction()
	-- Attempt to load the addon settings from the default settings folder
	local tempSettings = ashita.settings.load(_addon.path .. '/settings/trustee.json');
	if tempSettings ~= nil then 
		print('[Trustee][Load] Stored settings loaded.');
		addonSettings = tempSettings;
	else
		print('[Trustee][Load] Settings could not be loaded. Setting to default values.');
		addonSettings = defaultSettings();
	end
	
	-- Attempt to load the trust lists from the default settings folder
    local tempCommands = ashita.settings.load(_addon.path .. '/settings/trust_lists.json');
	if tempCommands ~= nil then
		print('[Trustee][Load] Stored trust list found.');
		trustList = tempCommands;
		
		-- If we are performing regular backups, then store the current trust lists as a backup file
		if addonSettings.backup then
			saveTrustList(os.time(),'LOAD');
		end				
	else
		print('[Trustee][Load] Trust Lists could not be loaded. Creating empty lists.');
		trustList = { };
	end
	
	-- Attempt to load the name map from the default settings folder
	local tempNames = ashita.settings.load(_addon.path .. '/settings/name_map.json');
	if tempNames ~= nil then 
		print('[Trustee][Load] Names map loaded.');
		nameList = tempNames;
	else
		error('[Trustee][Load] Names map could not be loaded. Check the addon settings folder for problems.');
	end
	
	-- Open the 'recent.script.txt' file if it exists, otherwise create a new file called 'recent.script.txt'
	-- This execution is performed to ensure the addon can have write access to the recent.script.txt file.
	scriptFile = assert( io.open(_addon.path .. '/settings/recent.script.txt', 'w+') );
	scriptFile:close();
	scriptFile = nil;
	
	-- If verbose mode is enabled, then print the script file's save/load location
	if addonSettings.verbose then
		print('[Trustee][Load][Verb] File \'recent.script.txt\' was successfully opened from ' .. _addon.path .. 'settings');
	end
	
	-- If verbose mode is enabled, then print the lists currently held in memory.
	if addonSettings.verbose then
		printCurrentTrustLists('[Load][Verb]');
	end
end

--------------------------------------------------------------
-- Unload Function: 
-- Called when the addon is being unloaded. Also called after
-- a reload command is entered, before the load function.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function unloadFunction()
    -- Save the addon settings to a file
	saveSettings('[Unload]');
	
	-- Save the command list to a file without a backup tag
	saveTrustList('','[Unload]');
	
	-- If the script file pointer is still open, close it here
	if scriptFile ~= nil then
		scriptFile:close();
	end
end

--------------------------------------------------------------
-- Command Function:
-- Called whenever a command is entered in the game. Further
-- parsing is required once this function is called. If the
-- command is determined to be for this addon, return true.
-- Otherwise return false.
-- Args: a string representing the entered command.
-- Return: true if the command is handled by this addon.
--------------------------------------------------------------
function commandFunction(command, commandType)
	-- Break the incoming player command into individual tokens
	local parameters = command:args();
	
	-- Get the number of tokens in the command
	local tokenCount = length(parameters);
	
	-- If the user uses /trustee or /tr then it belongs to us,
	-- so we should process it here. Otherwise we let Ashita
	-- fall through to the next addon.
	if parameters[1] == '/trustee' or parameters[1] == '/tr' then
		-- If verbose is enabled, print the current command
		if addonSettings.verbose then 
			print('[Trustee][Command][Verb] Received Command = ' .. command 
			      .. ', Token Count = ' .. tokenCount);
		end
		
		-- If our command has exactly two tokens, process it here.
		-- Commands with two tokens:
		--   trustee tName
		--   trustee list
		--   trustee save
		--   trustee backup
		--   trustee help
		if tokenCount == 2 then
			-- Handle the case for a list command
			if parameters[2] == 'list' then
				-- Print the current list from the command function
				printCurrentTrustLists('[List]');
				
				-- Finished processing this command
				return true;
			end
		
			-- Handle the case for a save command
			if parameters[2] == 'save' then
				-- Save the addon settings to a file
				saveSettings('[Unload]');
				
				-- Save the command list to a file without a backup tag
				saveTrustList('','[Unload]');
				
				-- Print confirmation
				print('[Trustee][Save] The addon settings and Trust list have been saved.');
				
				-- Finished processing this command
				return true;
			end
		
			-- Handle the case for a backup command
			if parameters[2] == 'backup' then
				-- If verbose, print the initiating message.
				if addonSettings.verbose then
					print('[Trustee][Backup][Verb] Initiating a new backup.');
				end 
				
				-- Perform a backup with the current OS time code.
				saveTrustList(os.time(),'[Backup]');
				
				-- Finished processing this command
				return true;
			end
			
			-- Handle the case for a help command
			if parameters[2] == 'help' then
				-- Display the general help block.
				displayHelp();
				
				-- Finished processing this command
				return true;
			end
			
			-- Handle the case for a tName command. This must be at the end of the
			-- TokenCount(2) if statement to avoid cross-pollenating with other commands.
			if summonTrustParty(parameters[2]) then
				return true;
			end
		end
		
		-- If our command has exactly two tokens, process it here.
		-- Commands with two tokens:
		--   trustee verbose (yes/no)
		--   trustee backup yes/no
		--   trustee remove tName
		--   trustee help commandName
		--   trustee char charName
		if tokenCount == 3 then
			-- Handle the case for a verbose command
			if parameters[2] == 'verbose' then
				-- Turn the verbose mode on or off based on the input.
				-- If the input is not correct, produce an error.
				if parameters[3] == 'on' then 
					addonSettings.verbose = true;
					print('[Trustee][Verbose] Verbose Mode ON');
				elseif parameters[3] == 'off' then
					addonSettings.verbose = false;
					print('[Trustee][Verbose] Verbose Mode OFF');
				else
					print('[Trustee][Verbose] Incorrect syntax for verbose command. Proper syntax: /trustee verbose on/off');
				end
				
				-- Finished processing this command
				return true;
			end
			
			-- Handle the case for a backup toggle command
			if parameters[2] == 'backup' then
				-- Turn the backup mode on or off based on the input.
				-- If the input is not correct, produce an error.
				if parameters[3] == 'on' then 
					addonSettings.backup = true;
					print('[Trustee][Backup] Backup Mode ON. The trust list will be backed up every time the addon loads.');
				elseif parameters[3] == 'off' then
					addonSettings.backup = false;
					print('[Trustee][Backup] Backup Mode OFF. The trust list will no longer automatically be backed up.');
				else
					print('[Trustee][Backup] Incorrect syntax for backup command. Proper syntax: /trustee backup on/off');
				end
				
				-- Finished processing this command
				return true;
			end
			
			-- Handle the case for a backup toggle command
			if parameters[2] == 'remove' then
				-- Remove the given trust set from the trust list.
				-- If no trust set exists, say so.
				if trustList[parameters[3]] == nil then
					print('[Trustee][Remove] There is no trust set named "'.. parameters[3] .. '" in the list.');
				else
					trustList[parameters[3]] = nil;
					print('[Trustee][Remove] Trust set "' .. parameters[3] .. '" has been removed.');
				end
				
				-- Finished processing this command
				return true;
			end		

			-- Handle the case for an individual help command
			if parameters[2] == 'help' then
				-- Display the individual help information for the given command
				displayIndividualHelp(parameters[3]);
				
				-- Finished processing this command
				return true;
			end	
			
			-- Handle the case for a char command (two-part names)
			if parameters[2] == 'char' then
				-- Print the character shorthand information, if it exists
				printCharacterShorthandNames(parameters[3]);
				
				-- Finished processing this command
				return true;
			end
		end
		
		-- If our command has more than three tokens, process it here.
		-- Commands with more than three tokens:
		--   trustee add SetName ListOfCharNames
		--   trustee add SetName party
		--   trustee char charNamePart1 charNamePart2
		if tokenCount > 3 then
			-- Handle the case for a char command (two-part names)
			if parameters[2] == 'char' then
				-- Print the character shorthand information, if it exists.
				-- The input is a string concatenation of a name split up
				-- by the command:args() function.
				printCharacterShorthandNames(parameters[3] .. ' ' .. parameters[4]);
				return true;
			end
			
			-- Handle the case for an add command 
			if parameters[2] == 'add' then
				-- Data Format: /command add setName CommaSeparatedListOfNames
				-- If the name entered is a Trustee reserved word, cancel and alert the user
				if not nameIsValid(parameters[3]) then
					print('[Trustee][Add] The name "' .. parameters[3] .. '" is reserved. Try again with another name.');
					return true;
				end
				
				-- Extract all the relevant information for easy usage.				
				local setName = parameters[3];
				local setCiphers = nil;
				
				-- If we're doing a party add, we collect the party names
				-- and extract the cipher list from them. If we're doing a
				-- regular add we extract the cipher list from the parameters.
				if parameters[4] == 'party' then
					setCiphers = { };
					
					-- Extract each name from the party list. If it's a cipher, store it in the cipher set.
					for i=0, AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount()-1 do
						local cipherName = AshitaCore:GetDataManager():GetParty():GetMemberName(i):lower();
						if isCipher(cipherName) then
							table.insert(setCiphers, cipherName);
						end
					end

					-- If we found zero ciphers in the party, we cannot create a set and print an error.
					if length(setCiphers) == 0 then
						print('[Trustee][Add][Party] Cannot create a Trust set. Your party has no Trusts to store.');
						return true;
					end
				else
					-- The list of names can be a single element or multiple, but
					-- the 'getCipherNames' function can handle that.
					setCiphers = getCipherNames(parameters);				
				end

				-- Convert the Cipher short names to the Trust spell names
				for i=1,length(setCiphers) do
					-- Retrieve the full name from the name map
					local tempCipher = getCipherNameFromShorthand(setCiphers[i])
									
					-- If the name wasn't matched, tell the user and cancel this command.
					if tempCipher == nil then
						print('[Trustee][Add] "' .. setCiphers[i] .. '" does not match any Trust names.' 
							  .. ' Change the name and try your command again.');
						return true;
					end
					
					-- Replace the shorthand name with the full name
					setCiphers[i] = tempCipher;
				end
				
				-- Check for a table entry update vs. a creation
				local tableState = trustList[setName] == nil and 'created' or 'updated';
				
				-- Add the information to the trust lists table
				trustList[setName] = setCiphers;
						
				-- Convert the cipher list to a string
				local cipherString = '';
				for i=1,length(setCiphers) do
					cipherString = cipherString .. setCiphers[i] .. ', ';
				end 
				
				-- Inform the user of the changes
				print('[Trustee][Add] Successfully ' .. tableState .. ' "' .. setName .. '" trust set with: '
					  .. '[' .. cipherString:sub(1, cipherString:len()-2) .. ']');
				
				-- Finished processing this command
				return true;
			end
		end
		
		-- If no valid command was given after /trustee or /tr, print a message
		print('[Trustee][Command] You entered an invalid or incomplete command "' .. command .. '". Enter "/trustee help" for addon information or try again.');
		
		-- If we are here, the command was for Trustee, but had invalid syntax
		return true;
	end

	-- If we arrive here, then the command is not meant for this addon; let it fall through
	return false;
end

--------------------------------------------------------------
-- Register all event functions with Ashita.
--------------------------------------------------------------
ashita.register_event('load', loadFunction);
ashita.register_event('unload', unloadFunction);
ashita.register_event('command', commandFunction);

--************************************************************
--*                                                          *
--*      Non-Ashita Built-In Functions After This Point      *
--*                                                          *
--************************************************************

--------------------------------------------------------------
-- saveSettings Function: 
-- When called, the addonSettings table is immediately saved
-- to a file. Announces saving process with verbose mode on.
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function saveSettings(location)
	-- If verbose mode is enabled, tell the user where the addon settings are saved
    if addonSettings.verbose then
		print('[Trustee]' .. location .. '[Verb] Saving Addon Settings to ' 
			  .. _addon.path .. 'settings\\trustee.json');
	end
	
	-- Save the addon settings to a file
	ashita.settings.save(_addon.path .. '/settings/trustee.json', addonSettings);
end

--------------------------------------------------------------
-- saveTrustList Function: 
-- When called, the trustList table is immediately saved
-- to a file. Announces saving process with verbose mode on.
-- If an argument is included, it will be appended to the end
-- of the file name, before the extension.
-- Parameters: string to append to the file name. Default = ''
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function saveTrustList(backupTag, location)
	-- If verbose mode is enabled, tell the user where the trust lists are saved
	if addonSettings.verbose or backupTag ~= '' then
		print('[Trustee]' .. location .. (addonSettings.verbose and '[Verb]' or '') .. ' Saving Trust Lists to ' 
			  .. _addon.path .. 'settings' .. (backupTag ~= '' and '\\backup' or '') 
			  .. '\\trust_lists' .. backupTag .. '.json');
	end
	
	-- Save the addon settings to a file (from the addonSettings table)
	ashita.settings.save(_addon.path .. '/settings' .. (backupTag ~= '' and '/backup' or '') 
						 .. '/trust_lists' .. backupTag .. '.json', trustList);
end

--------------------------------------------------------------
-- printCurrentTrustLists Function: 
-- When called, prints the entire set of trust lists to the
-- chat log. The list could be very long.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function printCurrentTrustLists(location)
	print('[Trustee]' .. location .. ' Current Trust Sets are');
	
	-- If there are no current trust lists, print the empty message.
	-- Otherwise print the entries in a numbered list.
	if next(trustList) == nil then
		print('     No Trust Lists Created\n');
	else
		local count = 1;
		local currentSet = '';
		for k, v in pairs(trustList) do
			currentSet = '';
			for _, s in pairs(v) do 
				currentSet = currentSet .. s .. ', ';
			end
			currentSet = ((currentSet:len() > 0) and currentSet:sub(1,currentSet:len()-2)) or 'Empty';
			print('     ' .. count .. '. ' .. k .. ' -> [' .. currentSet .. ']');
			count = count + 1;
		end
		print(' ');
	end	
end

--------------------------------------------------------------
-- printCurrentTrustLists Function: 
-- When called, prints the entire set of trust lists to the
-- chat log. The list could be very long.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function printCharacterShorthandNames(charName)
	if nameList[charName] == nil then
		print('[Trustee][Char] There is no Trust named "' .. charName .. '". Check the spelling and try again.');
		return;
	end
	
	print('[Trustee][Char] Trust Shorthand Naming Information:');
	print(' ');
	print('Trust Name: ' .. charName);
	print(' ');
	print('Unique Names: ' .. charName .. ', ' .. getNameSetString(charName) );
	print(' ');
	print('These unique names can be used with /tr add in the TrustList to add ' .. charName .. ' to a Trust set.');
	print('For more information on creating Trust sets, use the "/tr help add" command.');
	print(' '); 
end

--------------------------------------------------------------
-- getTrustSetString Function: 
-- When called, returns a string representing the trust set 
-- with the name provided.
-- Returns: a string representation of the named trust set.
--------------------------------------------------------------
function getTrustSetString(setName)
	local outputString = '';
	
	-- If the trust set does not exist, simply return "Empty"
	if trustList[setName] == nil then
		return 'Empty';
	end
	
	-- Add all trust names to the output string
	for _, s in pairs(trustList[setName]) do
		outputString = outputString .. s .. ', ';			
	end		
	
	-- If there are any trusts in the list, return them. Otherwise return "Empty".
	return (outputString:len() > 0 and outputString:sub(1,outputString:len()-2)) or 'Empty';
end

--------------------------------------------------------------
-- getNameSetString Function: 
-- When called, returns a string representing the name list 
-- with the name provided.
-- Returns: a string representation of the named trust set.
--------------------------------------------------------------
function getNameSetString(trustName)
	local outputString = '';
	
	-- If the trust set does not exist, simply return "Empty"
	if nameList[trustName] == nil then
		return 'Empty';
	end
	
	-- Add all trust names to the output string
	for _, s in pairs(nameList[trustName]) do
		outputString = outputString .. s .. ', ';			
	end		
	
	-- If there are any names in the list, return them. Otherwise return "Empty".
	return (outputString:len() > 0 and outputString:sub(1,outputString:len()-2)) or 'Empty';
end

--------------------------------------------------------------
-- summonTrustParty Function: 
-- When called, attempts to summon the Trust set with the name
-- matching the input parameter. 
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function summonTrustParty(partyName)
	-- Check if the trustList contains a set with the name provided in partyName
	local trustSet = trustList[partyName];
	
	-- If the provided set name has no party associated with it, print an error and cancel this summon
	if trustSet == nil then
		print('[Trustee][Command] Trust summon failed. The Trust List does not contain a set named "' .. partyName .. '".');
		return false;
	end
	
	-- Create the script file required for summoning the Trust party and store it in the settings folder as recent.script.txt
	if not createSummoningScript(trustSet) then
		return false;
	end
	
	-- Execute the newly created script file as if the user ran the execute command
	print('[Trustee][Sets] Summoning Trust Set "' .. partyName .. '": [ ' .. getTrustSetString(partyName) .. ' ]   Starting in 4 seconds...');
	AshitaCore:GetChatManager():RunScript(true, '../addons/trustee/settings/recent.script.txt');
	
	return true;
end

--------------------------------------------------------------
-- createSummoningScript Function: 
-- When called, closes and opens the active script file, then
-- attempts to write a new Trust script inside.
-- Returns: true if successful, false otherwise.
--------------------------------------------------------------
function createSummoningScript(trustSet)
	-- If the script file is open, close it first
	if scriptFile ~= nil then
		scriptFile:close();
		scriptFile = nil;
	end
	
	-- Attempt to open and erase the recent.script.txt file in the settings folder
	scriptFile = assert( io.open(_addon.path .. '/settings/recent.script.txt', 'w+') );
	
	-- If the script couldn't be opened, produce an error and cancel the summoning
	if scriptFile == nil then
		print('[Trustee][Command] Cannot open recent.script.txt file in the addon settings folder. Reload the addon.');
		return false;
	end
	
	-- Add a command to unsummon any existing Trusts to the script file
	scriptFile:write('/refa all\n/wait 4\n');
	
	-- Add each Trust command to the script file, except the last
	for i=1,length(trustSet)-1 do
		scriptFile:write('/ma "' .. trustSet[i] .. '" <me>\n/wait 6\n');
	end
	
	-- Add the final Trust command to the file (does not require a <wait 6>)
	scriptFile:write('/ma "' .. trustSet[length(trustSet)] .. '" <me>');
	
	-- Force the buffer to write to the file without closing the file
	scriptFile:close();
	scriptFile = nil;
	
	-- File written successfully
	return true;
end

--------------------------------------------------------------
-- nameIsValid Function: 
-- When called, checks an incoming name against a set of addon
-- reserved words. If the name is reserved, return false. 
-- Otherwise return true.
-- Returns: true if name is valid, false otherwise
--------------------------------------------------------------
function nameIsValid(name)
	local reserved = { "add", "remove", "verbose", "backup", "list", "help" };
	
	-- Check the incoming name against the above reserved list.
	-- If the incoming name is in the reserved list, return false.
	for _, n in pairs(reserved) do
		if name == n then
			return false;
		end
	end
	
	-- The name is not reserved
	return true;
end

--------------------------------------------------------------
-- getCipherNames Function: 
-- When called, extracts the names of the desired ciphers from
-- the list of parameters. This function can break the Cipher
-- names out of any properly formatted list of names provided
-- by the user.
-- Return: a properly formatted table of Cipher names.
--------------------------------------------------------------
function getCipherNames(list)
	-- Data Format: /command add setName CommaSeparatedListOfNames
	-- Since we receive all parameters, we know the list of
	-- names has to start at index 4.
	local names = '';
	local outNames = { };
	
	-- Compress all the names into a single string
	for i=4,length(list) do
		names = names .. list[i];
	end
	
	-- Replace all the commas with spaces
	names = names:gsub(',', ' ');
	
	-- Split the string into lowercase tokens using space delimiters.
	-- Note this will remove all the "blank" cipher names provided 
	-- by the user, where the input included ",,".
	for i in names:gmatch("%S+") do
		table.insert(outNames,i:lower());
	end
		
	-- Return a table of Cipher names in proper format
	return outNames;
end

--------------------------------------------------------------
-- getCipherNameFromShorthand Function: 
-- When called, replaces all the short hand cipher names to
-- their exact trust spell names.
-- Return: a list of trust spell names.
--------------------------------------------------------------
function getCipherNameFromShorthand(cipher)
	-- Check every shorthand name of every cipher.
	-- If the shorthand name is found in a cipher's full name,
	-- return the full name.
	for k, v in pairs(nameList) do
		for i, s in pairs(v) do
			if s == cipher then
				return k;
			end
		end
	end
	
	-- If no name could be matched, return nil
	return nil;
end

--------------------------------------------------------------
-- isCipher Function: 
-- When called, checks to ensure the input cipher is in the
-- cipher list.
-- Return: true if the cipher exists, otherwise false.
--------------------------------------------------------------
function isCipher(cipher)
	-- Check every shorthand name of every cipher.
	-- If the shorthand name is found in a cipher's full name,
	-- return true.
	for k, v in pairs(nameList) do
		for i, s in pairs(v) do
			if s == cipher then
				return true;
			end
		end
	end
	
	-- If no name could be matched, return nil
	return false;
end

--------------------------------------------------------------
-- displayHelp Function: 
-- When called, prints the generic help block to the screen.
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function displayHelp()
	print(' ');
	print('[Trustee][Help] The Trustee addon uses /trustee or /tr for commands.');
	print('The addon functionality can be accessed using the following commands:');
	print('/trustee add SetName TrustList');
	print('     This command creates a Trust set named SetName which summons the Trusts in the TrustList.');
	print('/trustee add SetName party');
	print('     This command creates a Trust set named SetName which contains all the Trusts currently in your party.');
	print('/trustee remove SetName');
	print('     Removes the Trust set named SetName.');
	print('/trustee verbose on/off');
	print('     Turn verbose mode on or off.');
	print('/trustee save');
	print('     Save the current settings and Trust list to a file.');	
	print('/trustee backup on/off');
	print('     Turn backup mode on or off.');
	print('/trustee backup');
	print('     Perform an immediate backup of the current Trust list.');
	print('/trustee SetName');
	print('     Summon the Trust set named SetName. This process takes approximately 6 seconds per Trust in the set (max. 30).');
	print('/trustee list');
	print('     List all the currently stored Trust sets.');
	print('/trustee help add/remove/verbose/backup/setname/list');
	print('     Show more information related to the command you enter.');
	print('/trustee char TrustName');
	print('     Show information on the available shorthand names for the Trust character name entered.');
	print('/trustee help');
	print('     Show this help screen.');
	print(' ');
end

--------------------------------------------------------------
-- displayIndividualHelp Function: 
-- When called, prints the help block specific to the command.
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function displayIndividualHelp(commandName)
	-- Create a single empty line at the top of a help screen
	print(' ');
	
	-- Choose the correct command to display help for
	if commandName == 'add' then
		print('[Trustee][Help] Add Trust Set Command:');
		print(' ');
		print('Syntax: /trustee add SetName TrustList');
		print('Syntax: /trustee add SetName party');
		print('This command creates a new Trust set which may be summoned later using /tr SetName.');
		print('SetName can be any character string and uniquely identifies the registered set. If SetName is');
		print('     already a set name, it will be overwritten. Note that SetNames are case sensitive.');
		print('TrustList is a comma-separated list of Trust names which will be included in the set named SetName.');
		print('     Name capitalization does not matter. Any spaces included in the TrustList will be removed. For');
		print('     a list of shorthand names available for a given Trust (to include in a TrustList), please use');
		print('     the command /trustee char TrustName, where TrustName is the Trust\'s full name from the in-game');
		print('     Trust menu.');
		print('The following examples all create differently named sets with the exact same Trust characters:');
		print('     /trustee add set1 Apururu (UC), Semih Lafihna, Trion');
		print('     /tr add set2 apururu,semih, Trion');
		print('     /tr add set3 Apururu,semih,trion');
		print('     /tr add set4 aPuRuRu,Semih Lafihna, TRION');
		print('Rather than including a list of Trusts, you may use the "party" keyword. This will create a Trust set');
		print('containing the Trusts which are currently present in your party. Note that this is incompatible with');
		print('alternate versions of Trusts (such as Lion vs. Lion II) because the game does not differentiate those');
		print('Trusts once they\'re in your party. For example, after summoning Lion II, her name will appear as Lion in');
		print('the party list and thus Trustee will only save their default name (Lion, not Lion II) in the Trust set.');
	elseif commandName == 'remove' then
		print('[Trustee][Help] Remove Trust Set Command:');
		print(' ');
		print('Syntax: /trustee remove SetName');
		print('SetName can be any character string and uniquely identifies the registered set. If SetName references');
		print('     a set in the trust set database, the associated Trust set will be removed. Otherwise this command');
		print('     will do nothing except show an alert message. Note that SetNames are case sensitive.');
	elseif commandName == 'verbose' then
		print('[Trustee][Help] Verbose Toggle Command:');
		print(' ');
		print('Syntax: /trustee verbose on/off');
		print('Toggles verbose mode on or off, depending on which command you use. While turned on, verbose mode will');
		print('     generate more messages about subsequent commands as they are entered.');
	elseif commandName == 'backup' then
		print('[Trustee][Help] Backup Commands:');
		print(' ');
		print('Syntax: /trustee backup');
		print('Initiates an immediate backup of the Trust set database. Backups are found in the addon settings folder.');
		print(' ');
		print('Syntax: /trustee backup on/off');
		print('Toggles automatic backups on or off, depending on which command you use. While turned on, the Trustee');
		print('     addon will perform an automatic backup of the pre-load Trust set database. See above for backup location.');
	elseif commandName == 'setname' then
		print('[Trustee][Help] Summon Trust Set Command:');
		print(' ');
		print('Syntax: /trustee SetName');
		print('This command summons the Trust set uniquely identified by the SetName value. If the SetName value');
		print('     is not found in the Trust set database, no Trust set will be summoned. Note that SetNames');
		print('     are case sensitive.');
		print('The summoning process uses regular macro-style wait commands to ensure proper Trust cast timing.');
		print('The length of time required to summon a Trust set is based on size and takes the following times:');
		print('     1 Trust  = 10 seconds');
		print('     2 Trusts = 16 seconds');
		print('     3 Trusts = 22 seconds');
		print('     4 Trusts = 28 seconds');
		print('     5 Trusts = 34 seconds');
	elseif commandName == 'list' then
		print('[Trustee][Help] List Trust Sets Command:');
		print(' ');
		print('Syntax: /trustee list');
		print('This command shows all stored Trust sets in a numbered list in the format of SetName -> TrustList.');
	elseif commandName == 'char' then
		print('[Trustee][Help] Trust Character Shorthand Names Command:');
		print(' ');
		print('Syntax: /trustee char TrustName');
		print('This command will show the possible shorthand names for the Trust character\'s name entered. When');
		print('     entering names into the TrustList in a /tr add command, you may use a Trust\'s full name or');
		print('     one of the available shorthand names provided by this command.');
	else
		print('[Trustee][Help] No help information available for "' .. commandName .. '".');
	end
	
	-- Create a single empty line at the bottom of a help screen
	print(' ');
end

--------------------------------------------------------------
-- length Function: 
-- When called, returns the number of elements in a list/table.
-- Alternative to the '#' operator, which has the potential to
-- be incredibly inconsistent.
-- Return: an integer representing the length of the input.
--------------------------------------------------------------
function length(list)
	local count = 0;
	
	for _ in pairs(list) do 
		count = count + 1;
	end
	
	return count;
end

--------------------------------------------------------------
-- defaultSettings Function: 
-- When called, returns a table containing the default addon
-- settings.
-- Return: a table containing the default addon parameters.
--------------------------------------------------------------
function defaultSettings()
	return 
	{	
		verbose = false;
		backup = false;
	}; 
end