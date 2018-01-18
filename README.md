# Extract-WAV-Data
This code repository provides a tool used to extract RCA COSMAC byte data encoded in WAV files.
The program is written in the Processing/Java language and does not use any other libraries. You will need the Processing SDK to run the program tool.
You can download the Processing SDK from 

https://processing.org

To use this program, a WAV audio file must first be converted into a signed 8-bit PCM raw data file.
I use the sound editor "Audacity" to isolate a single channel of WAV file audio 
representing one COSMAC program (not copies in the WAV file)
and then export the isolated audio segment as a raw signed 8-bit PCM file.
The raw file does not have the WAV file header.

https://www.audacityteam.org/download/

## Data Tape Format
A data byte stored on the tape begins with a "1" start bit, followed by 8 data bits, and ends with an odd parity bit.
A program is preceded by multiple 0 bits for synchronization, until the first start bit.

## RCA Coin Arcade Games and FRED Tape Encoding
The program tool only works for this type of data for now.
The COSMAC Arcade Game tapes sound data use two cycles of 2000 HZ to represent a 0 bit, and five cycles of 2000 HZ to represent a 1 bit.

## COSMAC VIP Tape Encoding
(Not tested, the tool will need to be modified for VIP tape data)

The COSMAC VIP program data tapes use one cycle of 2000 HZ to represent a 0 bit, and one cycle of 800 HZ to represent a 1 bit.

Screenshot of Coin Arcade Game Swords data waveforms in Audacity Sound Editor

![Screenshot of data waveform in Audacity](screenshot/waveform.png)

Written by Andy Modla
