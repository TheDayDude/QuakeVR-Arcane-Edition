// vr_input.hpp -- controller input.

#pragma once

#include "vr_backend.hpp"
#include "vr_hands.hpp"

namespace qvr::input
{

void init();
// Physical left D-pad: 3..6 = Up/Down/Left/Right, with a tome in either hand.
[[nodiscard]] int magicButton();
// Stick clicks while a tome is held: off bit 0, main bit 1. Never stick deflection.
[[nodiscard]] int magicSticks();

// Once per host frame with the backend's input.
void update(const InputState& in);

// Once per host frame after the hands: a jump in the room jumps in the game (vr_roomscale_jump).
void roomscaleJump(const hands::State& s);

// Whether the hand's upper face button (B on the main hand, Y on the off hand, by role) is held in the game: the
// grappling hook's reel (QVR_BUTTON_*HANDSECONDARY). Not while a menu or the console is up, nor when the posing mode,
// a voice note or the flashlight took the press.
[[nodiscard]] bool secondaryHeld(int hand);
// The same for the lower face button (A on the main hand, X on the off hand): the grappling hook's unreel
// (QVR_BUTTON_*HANDPRIMARY). Its key (jump, reload) is pressed as ever.
[[nodiscard]] bool primaryHeld(int hand);

// svc_quakevr QVR_SVC_HAPTIC (vr_client.cpp dispatches it).
void parseHaptic();

} // namespace qvr::input
