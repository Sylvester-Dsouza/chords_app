import 'package:flutter/material.dart';
import '../../widgets/inner_screen_app_bar.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedString = 'E';
  double _currentFrequency = 82.41; // E2 standard frequency
  bool _isInTune = false;
  double _tuningOffset = 0.0; // -1.0 to 1.0, where 0 is in tune
  
  final Map<String, double> _standardTuning = {
    'E': 82.41, // E2 (low E)
    'A': 110.00, // A2
    'D': 146.83, // D3
    'G': 196.00, // G3
    'B': 246.94, // B3
    'e': 329.63, // E4 (high E)
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Simulate tuning detection
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectString(String string) {
    setState(() {
      _selectedString = string;
      _currentFrequency = _standardTuning[string]!;
      _tuningOffset = 0.0; // Reset tuning offset
      
      // Simulate random tuning for demo purposes
      _tuningOffset = (DateTime.now().millisecond % 20 - 10) / 10;
      _isInTune = _tuningOffset.abs() < 0.1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Guitar Tuner',
      ),
      body: Column(
        children: [
          // Tuner display
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
                  // Selected string
                  Text(
                    _selectedString,
                    style: TextStyle(
                      color: _isInTune ? const Color(0xFF4CAF50) : Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tuning meter
                  Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Meter background
                        Container(
                          height: 4,
                          color: const Color(0xFF333333),
                        ),
                        
                        // Center marker
                        Container(
                          height: 20,
                          width: 2,
                          color: const Color(0xFFFFC701),
                        ),
                        
                        // Tuning indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          left: MediaQuery.of(context).size.width / 2 - 24 + (_tuningOffset * 100),
                          child: Container(
                            height: 40,
                            width: 8,
                            decoration: BoxDecoration(
                              color: _isInTune ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Frequency display
                  Text(
                    '${_currentFrequency.toStringAsFixed(2)} Hz',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tuning status
                  Text(
                    _isInTune ? 'In Tune' : _tuningOffset < 0 ? 'Tune Up' : 'Tune Down',
                    style: TextStyle(
                      color: _isInTune ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // String selector
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Select String',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _standardTuning.keys.map((string) {
                    final isSelected = _selectedString == string;
                    return InkWell(
                      onTap: () => _selectString(string),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFC701) : const Color(0xFF333333),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            string,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Tuning selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const Text(
                  'Tuning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTuningOption('Standard', true),
                    _buildTuningOption('Drop D', false),
                    _buildTuningOption('Open G', false),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildTuningOption(String name, bool isSelected) {
    return InkWell(
      onTap: () {
        // Would update tuning frequencies
      },
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
          name,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFC701) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
