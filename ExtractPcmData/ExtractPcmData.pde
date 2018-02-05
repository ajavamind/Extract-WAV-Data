// MIT License //<>// //<>//
//
// Copyright (c) 2017-2018 Andrew Modla
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/*
 * Written by Andy Modla December 2017
 
 * This program converts COSMAC audio encoded data .wav file that have been converted 
 * into a signed single channel 8 bit PCM raw data file using Audacity sound editor.
 
 * The program reads a signed 8 bit PCM raw data file, finds runs of expected waveform patterns, 
 * converts run data into bytes, and stores results into a binary data file.
 *
 * The program expects the raw data input file in the "data" folder.
 * The output is stored in this file folder.
 *
 * The WAV file has to be converted into a signed 8-bit PCM file for a single audio channel.
 * The WAV file must be edited with Audacity to select a channel and region to use for data extraction,
 * and then exported as a signed 8-bit PCM raw data file.
 */

///////////////////////////////////////////////////////////////////////////////
// Change these variables to match the WAV data being extracted

static final int COSMAC_FRED_FORMAT = 1;
static final int COSMAC_VIP_FORMAT = 2;
// Select the tape format:
int TAPE_FORMAT = COSMAC_FRED_FORMAT; //COSMAC_VIP_FORMAT;

// Expected ROM size
//int ROM_SIZE = 0x300;    // 768
//int ROM_SIZE = 0x700;  // 1792
// Select the ROM/Program size expected
int ROM_SIZE = 0x800;  // 2048

// Set the phase variable for VIP encoded data
boolean risingEdge = true; // most often used
//boolean risingEdge = false; // phase reversal

// Set Input, Output, and optional Compare Filename
// PCM_FILENAME, OUT_FILENAME, COMPARE_FILENAME
// Comment out duplicate names

//String PCM_FILENAME = "S.572.2 special_1_of_16_VIP_bowling.wav_normal-4dB.raw"; // rising edge false
//String OUT_FILENAME = "S.572.2 special_1_of_16_VIP_bowling.wav_normal-4dB.raw.vip";

//String PCM_FILENAME = "S.572_1_of_16_VIP_bowling.wav_normal-4dB.raw";  // rising edge true
//String OUT_FILENAME = "S.572_1_of_16_VIP_bowling.wav_normal-4dB.raw.vip";

//String PCM_FILENAME = "S.572.3 side b.wav_vip_bowling_normalize_-4db.raw";
//String OUT_FILENAME = "S.572.3 side b.wav_vip_bowling_normalize_-4db.raw.vip";

//String PCM_FILENAME = "S.572.2.special.wav_1_of_16_edit_high_pass_normalize_0dB.raw";
//String OUT_FILENAME = "S.572.2.special.wav_1_of_16_edit_high_pass_normalize_0dB.vip";

//String PCM_FILENAME = "S.572.2.special.wav_1_of_16.raw";
//String OUT_FILENAME = "S.572.2.special.wav_1_of_16.raw.vip";

//String COMPARE_FILENAME = "";

//String PCM_FILENAME = "S.572.2 VIP special-1_of_5.wav_edit.raw";  // high pass filter, normalize
//String OUT_FILENAME = "S.572.2 VIP special-1_of_5.wav.vip";

//String PCM_FILENAME = "S.572_16_of_16.wav.raw";
//String OUT_FILENAME = "S.572_16_of_16.wav.raw.vip";

String PCM_FILENAME = "AUD_2464_09_B41_ID01_02 Swords_left_signed_8bit_pcm.raw";
String OUT_FILENAME = "AUD_2464_09_B41_ID01_02 Swords.wav.arc";
String COMPARE_FILENAME = "test3.arc";

//String PCM_FILENAME = "AUD_2464_09_B41_ID05_01 180 Space War (S2-A3) 512 Bytes.wav.VIP.raw";
//String OUT_FILENAME = "AUD_2464_09_B41_ID05_01 180 Space War (S2-A3) 512 Bytes.wav.VIP.arc";

//String PCM_FILENAME = "AUD_2464_09_B41_ID02_01 Coin Bowling.wav.left.1.raw";
//String PCM_FILENAME = "AUD_2464_09_B41_ID02_01 Coin Bowling.wav.raw";
//String PCM_FILENAME = "AUD_2464_09_B41_ID02_02 Coin Bowling X2 10 Frames.wav.raw";
//String PCM_FILENAME = "AUD_2464_09_B41_ID01_02 Swords.wav.raw";
//String OUT_FILENAME = "AUD_2464_09_B41_ID02_01 Coin Bowling.wav2.arc";
//String OUT_FILENAME = "AUD_2464_09_B41_ID02_02 Coin Bowling X2 10 Frames.wav.arc";
//String OUT_FILENAME = "AUD_2464_09_B41_ID02_01 Coin Bowling.wav.arc";
//String COMPARE_FILENAME = "AUD_2464_09_B41_ID02_01 Coin Bowling.wav.arc";

///////////////////////////////////////////////////////////////////////////////

// Working variables do not change
int SAMPLING_RATE = 96000;
int GAP_LOWER = -20; // swords, tag/bowl, coin bowling
int GAP_UPPER = 32; // swords, tag/bowl, coin bowling
int THRESHOLD = 100; // swords, tag/bowl
int SILENCE_GAP =  64; //range 24 to 64 for swords, tag/bowl

byte[] bits;
boolean done = false;
int runs[];
int runCount = 0;
byte[] samples;
boolean oddParity = false;

// debug variables
int loc = 0;

////////////////////////////////////////////////////////////////////////////////

void setup()
{
  size(640, 480);

  calcThreshold(TAPE_FORMAT);

  // Read raw signed 8-bit PCM data file 
  samples = loadBytes(PCM_FILENAME);

  // debug
  //for (int i=0; i<50; i++) { //<>//
  //  println(samples[i]);
  //}

  // create and clear working buffer
  bits = new byte[samples.length];
  for (int i=0; i<bits.length; i++) {
    bits[i] = 0;
  }

  // create and clear an array of runs
  runs = new int[samples.length];
  for (int i=0; i<runs.length; i++) {
    runs[i] = 0;
  }

  // calculate runs of bits
  if (TAPE_FORMAT == COSMAC_FRED_FORMAT) {
    calcRuns();
  } else {
    calcZeroCrossings(0);
  }

  // debug output
  println("Runs");
  for (int j=0; j < 4; j++) {
    for (int i=0; i < 16; i++) {
      print(" " + runs[i + 16*j]);
    }
    println();
  }

  // calculate bytes from runs expecting data sequence: (start bit, 8 data bits, parity bit)
  calcBinary(OUT_FILENAME, oddParity, ROM_SIZE);

  // optionally compare with previous binary file created using a different pcm file
  if (!COMPARE_FILENAME.equals("")) {
    if (compareFiles(OUT_FILENAME, COMPARE_FILENAME))
      println(OUT_FILENAME, " matches " + COMPARE_FILENAME);
    else
      println("Extraction does not match " + COMPARE_FILENAME);
  } else {
    println("No File to Compare");
  }

  println("Extraction completed");
}

void calcThreshold(int format) {
  if (format == COSMAC_FRED_FORMAT) {
    int FRED_CYCLES_PER_SECOND = 2000; 
    int SAMPLES_PER_CYCLE = SAMPLING_RATE / FRED_CYCLES_PER_SECOND;
    int GAP_SAMPLES_PER_CYCLE = (2*SAMPLES_PER_CYCLE)/3;
    int ONE_BIT = 5*GAP_SAMPLES_PER_CYCLE;
    int ZERO_BIT = 2*GAP_SAMPLES_PER_CYCLE;
    SILENCE_GAP = SAMPLES_PER_CYCLE;
    THRESHOLD = ZERO_BIT + (ONE_BIT - ZERO_BIT)/2;
    oddParity = false;
    println("FRED 2 THRESHOLD="+THRESHOLD + " SILENCE_GAP="+SILENCE_GAP);
  } else {
    // COSMAC_VIP format
    int VIP_ZERO_CYCLES_PER_SECOND = 2000; 
    int VIP_ONE_CYCLES_PER_SECOND = 800; 
    int ZERO_BIT_SAMPLES_PER_CYCLE = SAMPLING_RATE / VIP_ZERO_CYCLES_PER_SECOND;
    int ONE_BIT_SAMPLES_PER_CYCLE = SAMPLING_RATE / VIP_ONE_CYCLES_PER_SECOND;
    int ONE_BIT = ONE_BIT_SAMPLES_PER_CYCLE;
    int ZERO_BIT = ZERO_BIT_SAMPLES_PER_CYCLE;
    THRESHOLD = ZERO_BIT + (ONE_BIT - ZERO_BIT)/2;
    oddParity = true;
    println("COSMAC VIP THRESHOLD="+THRESHOLD );
  }
}

void draw() {
  textSize(96);
  background(0);
  textAlign(CENTER, CENTER);
  text("DONE", width/2, height/2);
}

/*
 * Calculate byte data from runs
 */
void calcBinary(String filename, boolean oddParity, int maxSize) {
  int errorLimit = 8;
  byte[] rom;
  byte[] data = new byte[runs.length/8];
  int counter = 0;
  int i = 1;
  int numberStartBits = 0;
  int sum = 1;
  if (oddParity)
    sum = 0;

  while ( i<runs.length) {
    if (numberStartBits == 0) {
      if (runs[i] < THRESHOLD) {
        i++;
        continue;
      }
    }
    // start bit
    if (runs[i] >= THRESHOLD) {
      numberStartBits++;
      int value = 0;
      int parity = 1;
      for (int j=0; j<8; j++) {
        value >>= 1;
        if (runs[i+j+1] >= THRESHOLD) {
          value |= 0x0080;
          parity ^= 1;
        }
      }
      i += 9;
      data[counter++] = (byte) value;
      if (runs[i] >= THRESHOLD) {
        if (parity != sum) {
          println("Parity Error at ROM Address: "+ hexAddr(counter-1) + " value "+ hexData(value) + " parity 1");
          errorLimit--;
          if (errorLimit == 0)
            break;
        }
      } else {
        if (parity == sum) {
          println("Parity Error at ROM Address: "+ hexAddr(counter-1) + " value "+ hexData(value) + " parity 0");
          errorLimit--;
          if (errorLimit == 0)
            break;
        }
      }
      i++;
    } else {
      println("start bit error "+ i + " "+ runs[i]);
      break;
    }
    if (counter == maxSize)  // assume data does not exceed this value
      break;
  }

  println("number of start bits "+numberStartBits);
  println("ROM size = "+counter);

  // show first and last bytes
  print("addr "+hexAddr(0)+ " | ");
  for (int k=0; k< 16; k++) {
    print(hexData(data[k])+" ");
  }
  println();
  print("addr "+hexAddr(counter-16) + " | ");
  for (int k=0; k< 16; k++) {
    if ((counter -16 + k) >= 0)
      print(hexData(data[counter -16 + k])+" ");
  }
  println();

  rom = new byte[counter];
  for (int k=0; k<counter; k++)
    rom[k] = data[k];
    
  if (counter == ROM_SIZE) {
    println("SIZE=0x"+ hexAddr(maxSize) +" Writing Program file: "+filename);
    saveBytes(filename, rom);
  }
  else {
    println("No ROM file written");
  }
}

void calcRuns() {
  // produce a 1 if pcm signed sample is within a given range
  int sample;
  for (int i = 0; i < samples.length; i++) {
    sample = samples[i];
    if ((sample >= GAP_UPPER) || (sample <= GAP_LOWER)) {
      bits[i] = 1;
      if (loc == 0) {
        loc = i;
        println("debug first location above sample range ="+hex(loc));
      }
    }
  }
  println("bits array completed");

  int value = 0;
  int numz = 0;
  int first =0;
  int last = 0;
  boolean flag = false;
  for (int i=0; i<bits.length; i++) {
    if (bits[i] == 0 ) {
      numz++;
      if (numz > SILENCE_GAP && (!flag)) {
        value = last-first;
        runs[runCount++] = value;
        flag = true;
      }
    } else {
      numz = 0;
      if (flag) {
        first = i;
        flag = false;
      } else {
        last = i;
      }
    }
  }
}

void calcZeroCrossings(int offset) {
  int sample;
  int prevSample = 0;
  int value = 0;
  int last = 0;
  for (int i = 0; i < samples.length; i++) {
    sample = samples[i] + offset;
    boolean mark = false;
    if (risingEdge)
      mark = (prevSample < 0) && (sample >= prevSample) && (sample >= 0);
    else
      mark = (prevSample > 0) && (sample <= prevSample) && (sample <= 0);
    if (mark) {
      value = i - last;
      last = i;
      runs[runCount++] = value;
    }
    prevSample = sample;
  }
}

/*
 * Compare two binary files
 */
boolean compareFiles(String filename1, String filename2) {
  byte[] file1 = loadBytes(filename1);
  byte[] file2 = loadBytes(filename2);
  boolean match = true;
  if (file1.length != file2.length) {
    println("files not same length");
    //match = false;
    //return match;
  }
  int length = file1.length;
  if (length > file2.length)
    length = file2.length;
  println("compare length = "+length);
  int counter = 8;
  for (int i=0; i< length; i++) {
    if (file1[i] != file2[i]) {
      println("mismatch "+filename1 + " and " + filename2 + " at "+ i + 
        " " + hex(file1[i]) + " " + hex(file2[i]));
      match = false;
      counter--;
      if (counter == 0)
        break;
    }
  }
  return match;
}

String hexAddr(int addr) {
  String val = hex(addr).substring(4);
  return val;
}

String hexData(int data) {
  String val = hex(data).substring(6);
  return val;
}