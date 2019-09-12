# Godot OpenVR FPS

![](https://docs.godotengine.org/en/3.1/_images/starter_vr_tutorial_sword.png)

This repository contains the source and other related files for the Godot VR starter tutorial, which can be found here:
https://docs.godotengine.org/en/3.1/tutorials/vr/vr_starter_tutorial.html

The tutorial covers how to create a first person shooter (FPS) VR game in Godot using GDscript. The project on this repository is the finished result of the Godot tutorial.

### Safety notice

Virtual Reality (VR) can cause seizures, discomfort, and other problems for some individuals. **Take breaks when required and follow the health and safety warnings for your Virtual Reality headset!**

## Project Features

* VR locomotion through teleportation and artificial movement.
  * Point and teleport locomotion by pressing the trigger while not holding any objects. This locomotion snaps the player instantly to the new position.
  * Artificial movement locomotion by moving the VR joystick and/or touch-pad. This locomotion 'moves' the player through 3D space, applying a slight vignette to reduce motion sickness.
* A RigidBody-based 3D object interaction system that uses the VR controllers.
  * Pick up, drop, and throw both normally RigidBody and Rigidbody-derived nodes.
  * Pick up objects using either with an Area node or a Raycast node.
* Interact with specially coded RigidBody-based objects.
  * Currently the project has: pistols, a shotgun, a sword, and some simple bombs.
  * There are simple targets that break into pieces when damaged.
* 3D UI with in-game instructions.
* The project *should* work with all major VR headsets.
* And more!

### Credits for the assets used in this project

> * The sky panorama was created by [CGTuts](https://cgi.tutsplus.com/articles/freebie-8-awesome-ocean-hdris--cg-5684).
> * The font used is Titillium-Regular
>   * The font is licensed under the SIL Open Font License, Version 1.1
> * The audio used are from several different sources, all downloaded from the Sonniss #GameAudioGDC Bundle ([License PDF](https://sonniss.com/gdc-bundle-license/))
>   * The folders where the audio files are stored have the same name as folders in the Sonniss audio bundle.
> * The OpenVR addon was created by [Bastiaan Olij](https://github.com/BastiaanOlij) and is released under the MIT license. It can be found both on the [Godot Asset Library](https://godotengine.org/asset-library/asset/150) and on [GitHub](https://github.com/GodotVR/godot-openvr-asset).
> * The initial project, 3D models, and scripts were created by [TwistedTwigleg](https://github.com/TwistedTwigleg).
