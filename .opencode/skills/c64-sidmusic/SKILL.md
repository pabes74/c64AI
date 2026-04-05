---
name: c64-sidmusic
description: Compose authentic C64 SID music using 1980s techniques, covering MOS 6581/8580 SID chip architecture, arpeggios, PWM, vibrato, and filter tricks.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  platform: commodore-64
  assembler: kickassembler
---

## 1. Objective

Generate authentic C64 SID music data or code that: - Uses the MOS
6581/8580 SID chip architecture - Emulates 1980s tracker/driver
constraints - Reflects stylistic elements of Jeroen Tel / Ben Daglish -
Maximizes expressiveness using only 3 voices

## 2. Hardware Constraints (MANDATORY)

### SID Voices

-   Voice 1: Lead / FX
-   Voice 2: Harmony / Arpeggio
-   Voice 3: Bass / Rhythm

### Waveforms

-   Triangle
-   Sawtooth
-   Pulse (with PWM)
-   Noise

### Key Limitations

-   Monophonic per voice
-   No true polyphony → simulate with arpeggios
-   Shared global filter

## 3. Core Techniques to Use

### Arpeggios (CRITICAL)

-   Fast chord simulation (1/32 or faster)
-   Major: 0, +4, +7
-   Minor: 0, +3, +7

### Pulse Width Modulation (PWM)

-   Continuous modulation for richness

### Vibrato

-   Fast LFO pitch modulation

### Filter Tricks

-   Low-pass sweeps
-   Resonance effects

### Hard Restart

-   Reset ADSR quickly between notes

### Waveform Switching

-   Change waveform mid-note

### Fake Drums

-   Kick: pitch drop
-   Snare: noise burst
-   Hi-hat: short noise

## 4. Composition Style Rules

### Structure

-   Intro → Main loop → Variation → Loop

### Tempo

-   125--150 BPM equivalent

### Melody

-   High-register, catchy leads
-   Slides and retriggering

### Bassline

-   Rhythmic and syncopated

### Harmony

-   Implied via arpeggios

## 5. Channel Role Assignment

  Voice   Role         Techniques Used
  ------- ------------ -----------------
  1       Lead         PWM, vibrato
  2       Chords       Fast arpeggios
  3       Bass/Drums   Pulse + noise

## 6. Output Format Options

### Option A: Assembly

-   6502 assembly (GoatTracker / SID Wizard)

### Option B: Tracker Data

-   Patterns, instruments, effects

### Option C: Pseudocode SID Driver

-   Register-level logic

## 7. Example Prompt

Create a Commodore 64 SID tune using authentic 1980s techniques.

Constraints: - 3 voices only - Arpeggios for chords - PWM on lead -
Vibrato and hard restart - SID-style drums - Filter modulation

Style: - Jeroen Tel / Ben Daglish inspired - Upbeat game music -
Loopable (32--64 steps)

Output: - 6502 assembly or tracker data - Include instrument definitions

## 8. Advanced Enhancements

-   Raster-time tricks
-   Digi samples via volume register
-   Ring modulation
-   Sync mode

## 9. Common Failure Modes

-   Avoid polyphonic chords
-   Avoid modern synth layering
-   Avoid long ADSR pads
-   Respect timing constraints
