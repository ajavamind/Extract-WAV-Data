# Extract-WAV-Data
This code repository provides a procedure and tool for extracting RCA COSMAC (CDP1801 and CDP1802 microprocessor) byte data programs encoded in WAV files.
The WAV files are digital copies of cassette tapes made in 1974-1976 by Joe Weisbecker to store COSMAC programs for 
FRED (Flexible Recreational Educational Device), Arcade, and VIP computer systems.

The Hagley Museum and Library, Wilmington, Delware, digitized the cassette tape audio to create the WAV files from the Joe Weisbecker archive accession number 2464, box 9, B41. The WAV files were purchased from the Hagley Library.

The program tool processes input in the form of a single raw signed 8-bit PCM data file (no header) that contains one program.
The WAV file from the Hagley Library is a stereo audio file recorded at a sampling rate of 96000 Hz stored as 32 bit floating point samples. The file has two copies of byte coded programs on both left and right channels. The WAV file must first be 
converted into a raw file for input into the tool. This approach was done to simplify the programming effort needed to code the tool.

## Processing/Java
The program tool is written in the Processing/Java language and does not use any other libraries. 
You will need the Processing SDK to run the program tool.
You can download the Processing SDK from 

https://processing.org

## Audacity Sound Editor
To use the program tool, the WAV file must first be converted into a signed 8-bit PCM raw data file for one channel and one program.
I use the sound editor "Audacity" to isolate a single channel of WAV file audio 
representing one COSMAC program (not multiple copies in the WAV file)
and then export the isolated audio segment as a raw signed 8-bit PCM file.
The raw file does not have the WAV file header.

Audacity is available for download from

https://www.audacityteam.org/download/

## Data Tape Format
A data byte stored on the tape begins with a "1" start bit, followed by 8 data bits, and ends with an parity bit.
The data bits are ordered as least significant bit first.
A program may be preceded by multiple 0 bits for synchronization, until the first start bit.

## RCA Coin Arcade Games and FRED Tape Encoding
The RCA COSMAC FRED 2/Arcade Game tapes sound data use two cycles of 2000 HZ to represent a 0 bit, 
and five cycles of 2000 HZ to represent a 1 bit.
This tape format uses even data parity.

## RCA COSMAC VIP Tape Encoding
The RCA COSMAC VIP program data tapes use one cycle of 2000 HZ to represent a 0 bit, 
and one cycle of 800 HZ to represent a 1 bit.
This tape format uses odd data parity.

## Example Data Waveform in Audacity Sound Editor

![Screenshot of Data Waveform in Audacity](screenshot/waveform.png)

The above screenshot example of RCA Arcade/FRED waveform data is a "01010010101". 
In the waveform example the first "1" bit is a start bit, and is followed by 8 data bits, 
and the waveform ends with a "1" parity bit (even parity).
The data byte value is hexadecimal "52" (least significant bits first). 
This example assumes preceeding "0" bits before the first data byte.

## Video Showing How To Use Audacity

https://youtu.be/AfX4LBK-_JA

Here is a link to video explaining how I used Audacity to help with the necessary WAV data extraction process.
There are easier shortcuts (such as trim) when using Audacity but the steps I talk about in the video get the job done.

## Extraction Procedure

You have to look at the waveform in Audacity to determine if the tape date encoding is either FRED2/Arcade or VIP formatted data.
Once you know that you can set a parameter variable in the code.

After isolating a single program segment, often the waveform needs enhancing. Here are at least two possible choices depending on the digitized source:

1. Use Audacity Effect options to Normalize Arcade and FRED format data to remove DC offset 
and set maximum amplification level -4.0 dB.  
OR  
2. If the VIP program WAV file has problems with low amplitude 2000 Hz high tones, do the following steps in Audacity.  
  A) After selecting the wave form, run the High pass filter at 2000 Hz with 6dB rolloff.   
  B) Next Normalize the selection to remove DC offset and set maximum amplitude to 0 dB.  

Make sure the project sampling rate is set to 96000 Hz (bottom left corner of Audacity window) 
when exporting a raw PCM data files. In Audacity to save a __signed 8-bit PCM raw__ file, you have to export your selection.
Use File->Export->Export As WAV, then change "save as type" to "other uncompressed files".
Pick raw (headerless) and signed 8-bit PCM data.

## Notes

1. I noticed some tapes only have 2047 bytes stored, so the 2048th byte is sometimes interpreted as garbage (manifested as a parity error, depending on how the trailing audio is trimmed. The last byte is probably correct despite the parity error.
2. Several programs may be stored sequentially in the WAV file. You have to isolate and extract each program individually.
3. A program may be stored as a variable number of 256 byte pages. The size of the code is not always fixed at 2048 bytes. If you do not know the number of pages, start with a ROM size of 2048 bytes and by trial and error decrease (multiples of 256 byte pages) until you do not see errors and the size makes sense.
4. Apparently some VIP tapes may have been recorded with phase reversals as pointed out in the RCA COSMAC VIP Instruction Manual documentation posted by Herb Johnson at http://www.retrotechnology.com/restore/VIP%20Tape%20Format.html To solve this issue there is a phase boolean variable that has to be changed to successfully extract a program from this kind of frequency phase shifted recording.

## References
Written by Andy Modla

Copyright 2018 Andrew Modla
