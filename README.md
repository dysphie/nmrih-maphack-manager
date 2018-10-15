# NMRiH Maphack Manager

A SourceMod alternative to native maphack management

### Information
"Maphacks" are text files used in No More Room in Hell for runtime manipulation of entities.
 By default, maps are limited to one maphack of the same name and its include files. This plugin seeks to expand its functionality by offering organized per-map config folders instead.

### Features
- Define per-map config folders whose contents are executed every round.
- Support for full and partial directory matches (e.g. "nmo_cabin" and "nmo_")
- Fetch maphacks from all sub-directories as well.
- Support for "disabled" folders. Maphacks in these sub-folders won't be loaded.
- Maphack library path configurable through console commands.

### Console Variables
- `sm_maphack_manager_library` Directory to scan for maphacks (default: `configs/maphack-manager`)
	
- `sm_maphack_manager_override`, Whether to prevent the native maphack system from executing. (default: `True`);

### Directory Structure Example:

Given the map `nmo_cabin`, the maphacks with a green tick will execute every round: