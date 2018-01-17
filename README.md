# Extract-WAV-Data
This code is a tool used to extract RCA COSMAC byte data encoded in WAV files.

To use this program, a WAV audio file must first be converted into a signed 8-bit PCM raw data file.
I use the sound editor "Audacity" to isolate a single channel of WAV file audio 
representing one COSMAC program (not copies in the WAV file)
and then export the isolated audio segment as a raw signed 8-bit PCM file.
The raw file does not have the WAV file header.

https://www.audacityteam.org/download/

The COSMAC sound data uses two cycles of 1000HZ(?) to represent a 0 bit and five cycles to represent a 1 bit.
The files expected are COSMAC FRED and VIP data.

![Screenshot of Audacity Program](Extract-WAV-Data/screenshot/waveform.png)

Written by Andy Modla
