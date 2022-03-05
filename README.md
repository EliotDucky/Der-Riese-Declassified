# Licence
 - These scripts are provided for reference, not for use.
 - Do not redistribute or create a custom map or mod without permission from myself and Ray (TZGhosts).

# Descriptions
 Der Riese: Declassified is a custom zombies map for Call of Duty: Black Ops III. Reworking content from the game's Der Riese remaster, "The Giant", gameplay content was added including many easter egg features. These are those that I have created.

## Cymbal Monkey Bomb Upgrade Quest
 This is a simple quest which requires the tracking of player kills with the equipment, then tracking whether the bomb has been thrown into the furnace.

 The logic requires careful consideration of who has the equipment, and how they should access the upgrade should someone upgrade before them. The answer to this is to make anyone who already has the monkey bombs, use the trigger to upgrade them; those that don't have the base monkey bombs can then retrieve upgraded cymbal monkeys from the box in place of the regular cymbal monkeys.

 This uses a GSH define file to specify the map specific components to make individual working possible using different assets (models and sounds). The GSH file is used by both the quest and modified weapon script such that there is no need to define values twice and all places that use them are updated when they are changed.

 The cymbal monkey weapon script works in the screaming from original Der Riese, when the monkey is thrown into the furnace (aside from in the upgrade quest). The intercommunication of when the screaming should activate is simply controlled by a level boolean, which is always checked for when the monkey bomb lands in the furnace.

## Grenade Upgrade Quest
 This was a simple modification of Nacht Der Untoten's red explosive barrel script. On Nacht, the number of barrels destroyed is tracked and when all are, a song playes. This song is simply replaced with a function call to give the upgraded grenades. The initialisation for the grenades is handled in a separate script.

## "I'm On Der Riese" Hidden Song
 This song played into a community classic meme of a young fan singing his own song about playing the map. The players pick up three of four books which have stickers on them, reading one of ["I'm", "On", "Der", "Reise"]; these books can be placed on the table containing the fourth book. When depositing the books, this will be however many the player has picked up - if all books have been picked up, all will be placed at once, if only two have been picked up, only those two will be placed.

 The second step is filling the book with souls. This was a great opportunity to learn client side code (CSC), ensuring that FX plays efficiently. The most challenging part was using clientfields to make server-side and client-side interact with each other. The zombies which have their souls sucked towards the table must be within a volume. This volume can easily be manipulated in the editor to be the precise dimensions desired as opposed to using a radius which may encircle areas which are not desired to count towards soul-filling.

## Punch Card Audio Easter Eggs
 Any number of punch cards can be hidden in the map, each with any number of their own randomised spawn points. This is completely scalable by simply adding more spawn points and simply typing `addAudio(SND_ALIAS);` into the setup (in the correct order), the script handles the rest. These cards can be taken to the punchcard machine and inserted. Script sets the orientation to a struct placed in radiant and moves them from one struct to another; this setup allows the punchcard models to be changed, with no changes to the script required, only the structs need to be relocated. When playing, the script also rotates reel models to make the machine feel alive.
