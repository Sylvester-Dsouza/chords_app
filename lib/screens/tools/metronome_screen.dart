import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/inner_screen_app_bar.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _metronomeTimer;
  int _bpm = 120;
  bool _isPlaying = false;
  int _beatsPerMeasure = 4;
  int _currentBeat = 0;
  String _timeSignature = '4/4';

  final List<String> _timeSignatures = ['2/4', '3/4', '4/4', '6/8'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _stopMetronome();
    _animationController.dispose();
    super.dispose();
  }

  void _startMetronome() {
    if (_isPlaying) return;
    
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });
    
    // Calculate interval in milliseconds
    final interval = (60 / _bpm * 1000).round();
    
    _metronomeTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      _currentBeat = (_currentBeat + 1) % _beatsPerMeasure;
      
      // Animate the pendulum
      if (_currentBeat == 0) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.reverse(from: 1.0);
      }
      
      setState(() {});
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _toggleMetronome() {
    if (_isPlaying) {
      _stopMetronome();
    } else {
      _startMetronome();
    }
  }

  void _changeBpm(int value) {
    setState(() {
      _bpm = value;
      if (_isPlaying) {
        _stopMetronome();
        _startMetronome();
      }
    });
  }

  void _setTimeSignature(String timeSignature) {
    setState(() {
      _timeSignature = timeSignature;
      
      // Update beats per measure based on time signature
      switch (timeSignature) {
        case '2/4':
          _beatsPerMeasure = 2;
          break;
        case '3/4':
          _beatsPerMeasure = 3;
          break;
        case '4/4':
          _beatsPerMeasure = 4;
          break;
        case '6/8':
          _beatsPerMeasure = 6;
          break;
      }
      
      if (_isPlaying) {
        _stopMetronome();
        _startMetronome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Metronome',
      ),
      body: Column(
        children: [
          // Metronome display
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BPM display
                  Text(
                    '$_bpm BPM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Time signature
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _timeSignature,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Beat indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_beatsPerMeasure, (index) {
                      final isCurrentBeat = _isPlaying && index == _currentBeat;
                      return Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isCurrentBeat ? const Color(0xFFFFC701) : const Color(0xFF333333),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Play/Stop button
                  GestureDetector(
                    onTap: _toggleMetronome,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isPlaying ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // BPM slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tempo (BPM)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                            if (_bpm > 40) {
                              _changeBpm(_bpm - 1);
                            }
                          },
                        ),
                        Text(
                          '$_bpm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            if (_bpm < 220) {
                              _changeBpm(_bpm + 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _bpm.toDouble(),
                  min: 40,
                  max: 220,
                  divisions: 180,
                  activeColor: const Color(0xFFFFC701),
                  inactiveColor: const Color(0xFF333333),
                  onChanged: (value) {
                    _changeBpm(value.round());
                  },
                ),
              ],
            ),
          ),
          
          // Time signature selector
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Time Signature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _timeSignatures.map((signature) {
                    final isSelected = _timeSignature == signature;
                    return InkWell(
                      onTap: () => _setTimeSignature(signature),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFC701).withOpacity(0.2) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFC701) : const Color(0xFF333333),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          signature,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFFC701) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
