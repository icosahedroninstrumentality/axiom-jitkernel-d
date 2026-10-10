module loader.tci;

import framework;

enum ChannelBytes : ubyte {
	U8  = 0b000,
	F8  = 0b001,
	U16 = 0b010,
	F16 = 0b011,
	U32 = 0b100,
	F32 = 0b101,
	U64 = 0b110,
	F64 = 0b111,
}

struct Channels {
	ChannelBytes ALPHA;
	ChannelBytes ADD_R;
	ChannelBytes ADD_G;
	ChannelBytes ADD_B;
	ChannelBytes SUB_C;
	ChannelBytes SUB_M;
	ChannelBytes SUB_Y;
	ChannelBytes CIE_X;
	ChannelBytes CIE_Y;
	ChannelBytes CIE_Z;
	ChannelBytes OK_L;
	ChannelBytes OK_A;
	ChannelBytes OK_B;
	ChannelBytes OK_C;
	ChannelBytes OK_H;
}

struct ImageData {
	ushort width;
	ushort height;
	Channels channels;
}

public void loadTCI (string file) {
	import std.file;
	
	auto data = read(file);
}
