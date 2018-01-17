// MIT License //<>//
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

byte[] bits;
boolean done = false;
int runs[];
int runCount = 0;
byte[] samples;
int SAMPLING_RATE = 96000;
int BUFSIZE = 60*SAMPLING_RATE;

int GAP_LOWER = -20; // SWORDS
int GAP_UPPER = 32; // swords
int THRESHOLD = 100;
int SILENCE = 64; // 32  range 24 to 64

String PCM_FILENAME = "AUD_2464_09_B41_ID01_02 Swords_left_signed_8bit_pcm.raw";
String OUT_FILENAME = "AUD_2464_09_B41_ID01_02 Swords.wav.arc";
String COMPARE_FILENAME = "test3.arc";

void setup()
{
  size(1024, 800);

  // Read raw signed 8-bit PCM data file 
  samples = loadBytes(PCM_FILENAME);
  
  // create and clear working buffer
  bits = new byte[BUFSIZE];
  for (int i=0; i<bits.length; i++) {
    bits[i] = 0;
  }
  
  // create and clear an array of runs
  runs = new int[samples.length];
  for (int i=0; i<runs.length; i++) {
    runs[i] = 0;
  }

  // produce a 1 if pcm signed sample is within a given range
  int sample;
  for (int i = 0; i < samples.length; i++) {
    sample = samples[i];
    if ((sample >= GAP_UPPER) || (sample <= GAP_LOWER)) {
      bits[i] = 1;
    }
  }
  println("bits array completed");
  
  // calculate runs of bits
  calcRuns();
  
  // debug output
  //for (int i=0; i< 40; i++) {
  //  println("run " + i+ " " +runs[i]);
  //}
  
  // calculate bytes from runs expecting data sequence: (start bit, 8 data bits, odd parity bit)
  calcBinary(OUT_FILENAME);
  
  // optionally compare with previous binary file created using a different pcm file
  if (compareFiles(OUT_FILENAME, COMPARE_FILENAME))
    println(OUT_FILENAME, " matches " + COMPARE_FILENAME);
  else
    println("Extraction does not match " + COMPARE_FILENAME);
    
  println("Extraction completed");
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
    match = false;
    return match;
  }
  for(int i=0; i< file1.length; i++) {
    if (file1[i] != file2[i]) {
      println("mismatch "+filename1 + " and " + filename2 + " at "+ i + 
      " " + hex(file1[i]) + " " + hex(file2[i]));
      match = false;
      break;
    }
  }
  return match;
}

/*
 * Calculate byte data from runs
 */
void calcBinary(String filename) {
  byte[] rom;
  byte[] data = new byte[runs.length/8];
  int counter = 0;
  int i = 1;
  while ( i<runs.length) {
    if (runs[i] == 0) {
      i++;
      continue;
    }
    // start bit
    if (runs[i] >= THRESHOLD) {
      int value = 0;
      int parity = 1;
      for (int j=0; j<8; j++) {
        value >>= 1;
        if (runs[i+j+1] > THRESHOLD) {
          value |= 0x0080;
          parity ^= 1;
        }
      }
      i += 9;
      data[counter++] = (byte) value;
      if (runs[i] > THRESHOLD) {
        if (parity != 1) {
          println("ROM "+ hex(counter-1) + " "+ hex(value) + " parity 0 error "+i+" "+ runs[i]);
        }
      } else {
        if (parity != 0) {
          println("ROM "+ hex(counter-1) + " "+ hex(value) + " parity 1 error "+i+" "+ runs[i]);
        }
      }
      i++;
    } else {
      println("start bit error "+ i + " "+ runs[i]);
      break;
    }
    if (counter == 2048)  // assume data does not exceed this value
      break;
  }
  
  println("ROM size = "+counter);
  for (int k=0; k< 16; k++) {
    print(hex(data[k]));
  }
  println();
  
  rom = new byte[counter];
  for (int k=0; k<counter; k++)
    rom[k] = data[k];
    
  saveBytes(filename, rom);
}

void calcRuns() {
  int value = 0;
  int numz = 0;
  int first =0;
  int last = 0;
  boolean flag = false;
  for (int i=0; i<bits.length; i++) {
    if (bits[i] == 0 ) {
      numz++;
      if (numz > SILENCE && (!flag)) {
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