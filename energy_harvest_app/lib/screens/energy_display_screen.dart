import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:video_player/video_player.dart';
import '../painters/energy_arc_painter.dart';
import '../services/fake_bluetooth_service.dart';
import '../widgets/scrolling_app_bar.dart';
import 'package:flutter/foundation.dart'; // Import foundation.dart for kDebugMode

class EnergyData {
  final double value;
  final DateTime timestamp;

  EnergyData(this.value, this.timestamp);
}

class EnergyDisplayScreen extends StatefulWidget {
  final BluetoothDevice device;
  final FakeBluetoothSerialService? fakeBluetoothService;

  EnergyDisplayScreen({required this.device, this.fakeBluetoothService});

  @override
  _EnergyDisplayScreenState createState() => _EnergyDisplayScreenState();
}

class _EnergyDisplayScreenState extends State<EnergyDisplayScreen> with TickerProviderStateMixin {

  // 에너지 퍼센트 차는 숫자를 나타냄
  late AnimationController _animationController;
  late Animation<double> _animation;

  //게이지 스크린 나타나는 에니메이션
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

  //에너지가 다 찼을때의 에니메이션
  late AnimationController _fullEnergyAnimationController;
  late Animation<double> _fullEnergyAnimation;

  //퍼센티지 사라지는 에니메이션
  late AnimationController _percentageFadeController;
  late Animation<double> _percentageFadeAnimation;

  late VideoPlayerController _introVideoController;
  late VideoPlayerController _secondVideoController;

  bool _showIntroVideo = true;
  bool _showSecondVideo = false;
  bool _showGauge = false;

  BluetoothConnection? connection;
  bool isConnecting = true;
  bool isDisconnecting = false;
  bool hasError = false;
  String errorMessage = '';

  List<EnergyData> energyValues = [];
  bool _isFullEnergy = false;
  double _fixedSum = 0.0;
  double _currentPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
    _initializeAnimations();
    connectToDevice();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _fadeInController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _showGauge = false; // Hide the gauge after fade-out
        });
      }
    });
  }

  void _initializeVideoControllers() {
    _introVideoController = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        setState(() {});
        _introVideoController.play();
        _introVideoController.addListener(_onIntroVideoEnd);
      });

    _secondVideoController = VideoPlayerController.asset('assets/videos/second_video.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void _onIntroVideoEnd() {
    if (_introVideoController.value.position >= _introVideoController.value.duration - const Duration(milliseconds: 100) &&
        !_introVideoController.value.isPlaying) {
      _introVideoController.removeListener(_onIntroVideoEnd);
      _resetGauge();
      setState(() {
        _showIntroVideo = false;
        _showGauge = true;
        _showSecondVideo = false;
      });
      _fadeInController.forward();

    }
  }


  void _onSecondVideoEnd() {
    if (_secondVideoController.value.position >= _secondVideoController.value.duration - const Duration(milliseconds: 100) &&
        !_secondVideoController.value.isPlaying) {
      _secondVideoController.removeListener(_onSecondVideoEnd);
      _restartIntroVideo();
    }
  }

  void _restartIntroVideo() async {
    await _introVideoController.pause();
    await _introVideoController.seekTo(Duration.zero);
    await _introVideoController.play();
    await Future.delayed(const Duration(milliseconds: 100)); // Small delay

    await _secondVideoController.seekTo(Duration.zero);
    _resetGauge();
    setState(() {
      _showSecondVideo = false;
      _showIntroVideo = true;
      _showGauge = false;
    });
    _introVideoController.addListener(_onIntroVideoEnd);
    _resetGauge();
  }


  void _resetGauge() {
    setState(() {
      _isFullEnergy = false;
      _fixedSum = 0.0;
      _currentPercentage = 0.0;
      energyValues.clear();
      _animationController.value = 0.0;
      _fadeInController.reset();
      _fullEnergyAnimationController.reset();
      _percentageFadeController.reset();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );



    _fullEnergyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fullEnergyAnimation = CurvedAnimation(
      parent: _fullEnergyAnimationController,
      curve: Curves.easeInOut,
    );

    _percentageFadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _percentageFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_percentageFadeController);

    _fullEnergyAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onGaugeComplete();
      }
    });
  }

  void _onGaugeComplete() {
    _fadeInController.reverse(); // Start the fade-out animation
    _secondVideoController.play(); // Start playing the second video
    setState(() {
      _showSecondVideo = true;
      // Do not set _showGauge to false yet
    });
    _secondVideoController.addListener(_onSecondVideoEnd);
  }




  void connectToDevice() async {
    if (widget.fakeBluetoothService != null) {
      await widget.fakeBluetoothService!.connect(widget.device);
      listenToFakeEnergyValues();
      setState(() {
        isConnecting = false;
      });
    } else {
      try {
        connection = await BluetoothConnection.toAddress(widget.device.address);
        print('Connected to the device');
        setState(() {
          isConnecting = false;
        });

        connection!.input!.listen(onDataReceived).onDone(() {
          if (isDisconnecting) {
            print('Disconnecting locally!');
          } else {
            print('Disconnected remotely!');
          }
          if (this.mounted) {
            setState(() {
              hasError = true;
              errorMessage = 'Disconnected from the device';
            });
          }
        });
      } catch (e) {
        print('Error connecting to the device: $e');
        setState(() {
          isConnecting = false;
          hasError = true;
          errorMessage = 'Failed to connect to the device';
        });
      }
    }
  }

  void listenToFakeEnergyValues() {
    widget.fakeBluetoothService!.getEnergyValues().listen((value) {
      updateEnergyValue(double.parse(value));
    });
  }

  void onDataReceived(Uint8List data) {
    String dataString = String.fromCharCodes(data).trim();
    print('Received data: $dataString');

    RegExp regExp = RegExp(r'(\d+(\.\d+)?)');
    Match? match = regExp.firstMatch(dataString);

    if (match != null) {
      String? valueString = match.group(1);
      if (valueString != null) {
        try {
          double value = double.parse(valueString);
          print('Parsed value: $value');
          updateEnergyValue(value);
        } catch (e) {
          print('Error parsing numeric value: $e');
        }
      }
    } else {
      print('No numeric value found in the data');
    }
  }

  void updateEnergyValue(double newValue) {
    if (!_isFullEnergy) {
      energyValues.add(EnergyData(newValue, DateTime.now()));

      DateTime cutoff = DateTime.now().subtract(const Duration(seconds: 5));
      energyValues = energyValues.where((data) => data.timestamp.isAfter(cutoff)).toList();

      _fixedSum = energyValues.fold(0.0, (prev, element) => prev + element.value);

      double newPercentage = (_fixedSum / 2500*100).clamp(0.0, 100.0);

      if (newPercentage >= 100) {
        _isFullEnergy = true;

        setState(() {
          _currentPercentage = newPercentage;
        });

        _fullEnergyAnimationController.forward();
        _percentageFadeController.forward();
        // No need to call _onGaugeComplete here since it's triggered by the animation's listener
      } else {
        setState(() {
          _currentPercentage = newPercentage;
          double targetAnimationValue = newPercentage / 100.0;
          _animationController.animateTo(
            targetAnimationValue,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.linear,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _introVideoController.removeListener(_onIntroVideoEnd);
    _secondVideoController.removeListener(_onSecondVideoEnd);
    _animationController.dispose();
    _fadeInController.dispose();
    _fullEnergyAnimationController.dispose();
    _percentageFadeController.dispose();
    _introVideoController.dispose();
    _secondVideoController.dispose();
    if (connection != null && connection!.isConnected) {
      isDisconnecting = true;
      connection!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallerDimension = size.width < size.height ? size.width : size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF323232),
      appBar: ScrollingAppBar(
        backgroundColor: Color(0xFFEBFF00),
        textColor: Colors.black,
        height: 50,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_showIntroVideo)
            _buildVideoPlayer(_introVideoController),
          if (_showSecondVideo)
            _buildVideoPlayer(_secondVideoController),
          if (_showGauge)
            FadeTransition(
              opacity: _fadeInAnimation,
              child: _buildGaugeScreen(size, smallerDimension),
            ),
        ],
      )



    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildGaugeScreen(Size size, double smallerDimension) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.10),
            _buildEnergyGauge(size, smallerDimension),
            // if (kDebugMode)
            //   Padding(
            //     padding: const EdgeInsets.all(8.0),
            //     child: ElevatedButton(
            //       onPressed: () {
            //         // Set the energy value directly to 100%
            //         updateEnergyValue(4000.0);
            //       },
            //       child: Text('Set Energy to 100%'),
            //     ),
            //   ),
            SizedBox(height: size.height * 0.07),
            _buildBottomText(size),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyGauge(Size size, double smallerDimension) {
    return AnimatedBuilder(
      animation: _fullEnergyAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _isFullEnergy ? size.height * 0.1 * _fullEnergyAnimation.value : 0),
          child: SizedBox(
            width: smallerDimension * 0.6,
            height: smallerDimension * 0.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildBackgroundCircle(smallerDimension),
                _buildEnergyArc(smallerDimension),
                if (!_isFullEnergy) _buildPercentageText(smallerDimension),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundCircle(double smallerDimension) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _fullEnergyAnimation]),
      builder: (context, child) {
        double opacity = 1.0 - _fullEnergyAnimation.value;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: smallerDimension * 0.58,
            height: smallerDimension * 0.58,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, _animation.value],
                  colors: const [Colors.white, Colors.transparent],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/images/background_inside_circle.png'),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyArc(double smallerDimension) {
    return AnimatedBuilder(
      animation: _fullEnergyAnimation,
      builder: (context, child) {
        double opacity = 1.0 - _fullEnergyAnimation.value;
        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: EnergyArcPainter(
              animation: _animationController,
              color: const Color(0xFFEBFF00),
              width: smallerDimension * 0.015,
            ),
            child: Container(),
          ),
        );
      },
    );
  }

  Widget _buildPercentageText(double smallerDimension) {
    return AnimatedBuilder(
      animation: Listenable.merge([_percentageFadeAnimation, _animationController]),
      builder: (context, child) {
        return Opacity(
          opacity: _percentageFadeAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                (_animationController.value * 100).toStringAsFixed(0),
                style: TextStyle(
                  fontSize: smallerDimension * 0.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                "%",
                style: TextStyle(
                  fontSize: smallerDimension * 0.075,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomText(Size size) {
    return AnimatedBuilder(
      animation: _fullEnergyAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - _fullEnergyAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "지금까지 ",
                    style: TextStyle(
                      fontFamily: 'SUIT',
                      color: Colors.white,
                      fontSize: size.width * 0.018,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "EPSD°",
                    style: TextStyle(
                      fontFamily: 'SUIT',
                      color: const Color(0xFFEBFF00),
                      fontSize: size.width * 0.02,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "와 함께 만들은 시너지",
                    style: TextStyle(
                      fontFamily: 'SUIT',
                      color: Colors.white,
                      fontSize: size.width * 0.018,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.width * 0.003),
              Text(
                "make synergy with episode",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.015,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SUIT',
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}