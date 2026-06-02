# Screen Plan

## Goal

Turn the root HTML references into a Flutter screen roadmap and route map.

## Screens To Add

1. Import Audio
2. Library
3. Audio Editor
4. Export / Download

Also needed:

* app shell and route map

## Route Map

* `/` -> import audio entry for now
* `/audio/import` -> import audio
* `/library` -> media library
* `/projects/audio-editor` -> beat-aware editor
* `/export/download` -> export and share

## Build Order

1. Import Audio
2. Library
3. Audio Editor
4. Export / Download

Reason:

* import audio is the current entry flow
* library is needed before editor asset workflows feel complete
* editor depends on beat map, timeline, and playback foundations already built
* export comes last because it depends on finished project state

## References

* [App Shell And Routing](./00-app-shell-and-routing.md)
* [Import Audio](./01-import-audio-screen.md)
* [Library](./02-library-screen.md)
* [Audio Editor](./03-audio-editor-screen.md)
* [Export Download](./04-export-download-screen.md)
