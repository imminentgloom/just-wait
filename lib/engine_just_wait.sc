// CroneEngine_just_wait
// SuperCollider engine for just wait
// Based on: https://sccode.org/1-1P8
Engine_just_wait : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
  ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg out, time = 0.4, feedback = 0.4, sep = 0, mix = 0, delaysend = 1, highpass = 400, lowpass = 5000;

      var t = Lag.kr(time, 0.2);
      var f = Lag.kr(feedback, 0.2);
      var s = Lag.kr(sep, 0.2);
      var d = Lag.kr(delaysend, 0.2);
      var h = Lag.kr(highpass, 0.2);
      var l = Lag.kr(lowpass, 0,2);


      var input = SoundIn.ar([0, 0]);
      var fb = LocalIn.ar(2);
      var output = LeakDC.ar((fb * f) + (input * d));

      output = HPF.ar(output, h);
      output = LPF.ar(output, l);
      output = output.tanh;

      output = DelayC.ar(output, 2.5, LFNoise2.ar(12).range([t, t + s], [t + s, t])).reverse;
      LocalOut.ar(output);

      Out.ar(out, LinXFade2.ar(input, output, mix));
    }.play(args: [\out, context.out_b], target: context.xg);

    this.addCommand("time", "f", { arg msg;
      synth.set(\time, msg[1]);
    });

    this.addCommand("feedback", "f", { arg msg;
      synth.set(\feedback, msg[1]);
    });

    this.addCommand("sep", "f", { arg msg;
      synth.set(\sep, msg[1]);
    });

    this.addCommand("mix", "f", { arg msg;
      synth.set(\mix, msg[1]);
    });

    this.addCommand("delaysend", "f", { arg msg;
      synth.set(\delaysend, msg[1]);
    });

    this.addCommand("highpass", "f", { arg msg;
      synth.set(\highpass, msg[1]);
    });

    this.addCommand("lowpass", "f", { arg msg;
      synth.set(\lowpass, msg[1]);
    });
  }

  free {
    synth.free;
  }
}
