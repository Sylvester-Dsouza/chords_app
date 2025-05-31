# Audio Assets for Practice Mode

This directory contains audio files for the metronome functionality.

## Required Files:

### 1. click.wav
- **Purpose**: Regular metronome beat
- **Duration**: ~100ms
- **Format**: WAV, 44.1kHz, 16-bit
- **Description**: Standard metronome click sound

### 2. accent.wav
- **Purpose**: Accented beat (first beat of measure)
- **Duration**: ~100ms
- **Format**: WAV, 44.1kHz, 16-bit
- **Description**: Higher pitched or louder click for emphasis

### 3. tick.wav
- **Purpose**: Count-in beats
- **Duration**: ~100ms
- **Format**: WAV, 44.1kHz, 16-bit
- **Description**: Distinct sound for count-in phase

### 4. kick.wav
- **Purpose**: Kick drum sound for accented beats
- **Duration**: ~150ms
- **Format**: WAV, 44.1kHz, 16-bit
- **Description**: Deep kick drum sound for downbeats

### 5. hihat.wav
- **Purpose**: Hi-hat sound for regular beats
- **Duration**: ~100ms
- **Format**: WAV, 44.1kHz, 16-bit
- **Description**: Crisp hi-hat sound for off-beats

## How to Add Audio Files:

### Option 1: Use Free Audio Resources
- Download from freesound.org
- Search for "metronome click" or "tick"
- Ensure files are royalty-free

### Option 2: Generate Programmatically
- Use audio editing software (Audacity, GarageBand)
- Create simple sine wave tones:
  - click.wav: 800Hz tone, 100ms
  - accent.wav: 1200Hz tone, 100ms
  - tick.wav: 600Hz tone, 100ms

### Option 3: Use System Sounds (Fallback)
If audio files are not available, the app will fall back to:
- Haptic feedback
- System notification sounds
- Visual-only metronome

## File Size Recommendations:
- Keep each file under 10KB
- Use compressed formats if needed
- Optimize for mobile playback

## Testing:
After adding files, test on both iOS and Android devices to ensure:
- Audio plays correctly
- No latency issues
- Proper volume levels
- Battery impact is minimal
