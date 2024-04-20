extends Node2D


var mode := [Base.FrameFiller1.new(0.15), Base.FrameFiller2.new(0.15), Base.BufferFiller1.new(0.15), Base.BuferFiller2.new(0.15)] as Array[Base]


func _init() -> void:
	for i in mode:
		i.process_thread_group = PROCESS_THREAD_GROUP_SUB_THREAD
	add_child(mode.front())


func _physics_process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var line: PackedVector2Array
	for i in range(0, Base.track.slice(0, int(Base.frame)).size()):
		line.append(Vector2(i, Base.track[i] * 32 + get_viewport_rect().size.y / 2))
	draw_polyline(line, Color.WHITE, 1.0, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released():
		if event.position.x > get_viewport_rect().size.x / 2:
			Base.exp.parse(Base.tests[randi_range(0, Base.tests.size() - 1)], ["phase", "time", "ternary"])
			Base.track.resize(0)
			var t := 0 as float
			var p := 0 as float
			for i in range(600):
				Base.track.append(Base.exp.execute([p, t, Base.ternary]))
				p = fmod(p + Base.increment, 1.0)
				t += 1.0 / 60.0
		else:
			mode.append(mode.pop_front())
			remove_child(mode.back())
			add_child(mode.front())


class Base:
	extends AudioStreamPlayer
	
	static var exp := Expression.new()
	static var tests := ["1", "sin(phase * TAU)", "exp(-fmod(time, 3.0))", "sin(phase * TAU) * exp(-time)",
		"ternary.call(1, phase < 0.5, 0)", "ternary.call(1, time < 5, sin(phase * TAU))",
		"ternary.call(exp(-time), time < 3, ternary.call(sin(phase * TAU), time < 6, 1))"]
	static var time := 0 as float
	static var phase := 0 as float
	static var increment := 440.0 / 44100.0
	static var track: PackedFloat32Array
	static var frame := 0
	
	
	func _init(buffer_length := 0.5) -> void:
		name = "Base"
		stream = AudioStreamGenerator.new()
		stream.buffer_length = buffer_length
		autoplay = true
		exp.parse(tests[1], ["phase", "time", "ternary"])
		var t := 0 as float
		var p := 0 as float
		for i in range(600):
			track.append(exp.execute([p, t, ternary]))
			p = fmod(p + increment, 1.0)
			t += 1.0 / 60.0
	
	
	static func ternary(t, c, f): return t if c else f
	
	
	class FrameFiller1:
		extends Base
		
		
		func _physics_process(delta: float) -> void:
			for i in get_stream_playback().get_frames_available():
				get_stream_playback().push_frame(Vector2.ONE * sin(phase * TAU) * exp.execute([phase, time, ternary]))
				phase = fmod(phase + increment, 1.0)
			time = fmod(time + delta, 10.0)
			frame = fmod(frame + 1, track.size())
	
	
	class FrameFiller2:
		extends Base
		
		
		func _physics_process(delta: float) -> void:
			for i in get_stream_playback().get_frames_available():
				get_stream_playback().push_frame(Vector2.ONE * sin(phase * TAU) * track[frame])
				phase = fmod(phase + increment, 1.0)
			time = fmod(time + delta, 10.0)
			frame = fmod(frame + 1, track.size())
	
	
	class BufferFiller1:
		extends Base
		
		
		func _physics_process(delta: float) -> void:
			var buffer: PackedVector2Array
			while get_stream_playback().can_push_buffer(buffer.size() + 60):
				for i in range(60):
					buffer.append(Vector2.ONE * sin(phase * TAU) * exp.execute([phase, time, ternary]))
					phase = fmod(phase + increment, 1.0)
			get_stream_playback().push_buffer(buffer)
			time = fmod(time + delta, 10.0)
			frame = fmod(frame + 1, track.size())
	
	
	class BuferFiller2:
		extends Base
		
		
		func _physics_process(delta: float) -> void:
			var buffer: PackedVector2Array
			while get_stream_playback().can_push_buffer(buffer.size() + 600):
				for i in range(600):
					buffer.append(Vector2.ONE * sin(phase * TAU) * track[frame])
					phase = fmod(phase + increment, 1.0)
			get_stream_playback().push_buffer(buffer)
			time = fmod(time + delta, 10.0)
			frame = fmod(frame + 1, track.size())
