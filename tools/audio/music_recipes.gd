class_name MusicRecipes
## Dev-only (tools/, never exported): the game's music (M13), one recipe per track, rendered by MusicSynth
## by tools/audio/generate_music.gd into assets/audio/music/<id>.wav (loops). A track is a chord progression
## in a scale with a few voices on top; the notes of the melody and the arpeggios come from the track's seed,
## so a regenerated track is the same one.
##   root: MIDI note of the key's tonic        scale: a SCALES key       bpm, bars: tempo and length of the loop
##   chords: scale degree of each bar's chord root (cycled over the bars)
##   bass: "root8" | "walk" | "long" | "pulse"        arp: "up" | "updown" | "broken" | "none" (+ arp_rate: notes a beat)
##   lead: "none" | "sparse" | "flowing" | "driving"  pad: true/false      drums: "none" | "soft" | "drive" | "boss"
##   lead_wave / lead_duty: the lead's oscillator   level: the track's loudness in the mix (the Music bus does the rest)

const SCALES: Dictionary = {
	"minor": [0, 2, 3, 5, 7, 8, 10],
	"harmonic": [0, 2, 3, 5, 7, 8, 11],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"major": [0, 2, 4, 5, 7, 9, 11],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
}

const TRACKS: Dictionary = {
	&"title": {"root": 57, "scale": "minor", "bpm": 72, "bars": 16, "chords": [0, 5, 2, 6, 0, 5, 3, 4], "bass": "long", "arp": "updown", "arp_rate": 2,
		"lead": "sparse", "pad": true, "drums": "none", "lead_wave": "triangle", "level": 0.8, "seed": 11},
	&"war_room": {"root": 50, "scale": "dorian", "bpm": 66, "bars": 16, "chords": [0, 3, 0, 4, 5, 3, 1, 4], "bass": "long", "arp": "broken", "arp_rate": 2,
		"lead": "none", "pad": true, "drums": "none", "level": 0.7, "seed": 12},
	&"map": {"root": 52, "scale": "minor", "bpm": 84, "bars": 16, "chords": [0, 6, 5, 6, 0, 3, 4, 4], "bass": "pulse", "arp": "up", "arp_rate": 2,
		"lead": "sparse", "pad": false, "drums": "soft", "lead_wave": "square", "lead_duty": 0.25, "level": 0.75, "seed": 13},
	&"fight_1": {"root": 57, "scale": "minor", "bpm": 126, "bars": 16, "chords": [0, 0, 5, 6, 0, 0, 3, 4], "bass": "root8", "arp": "up", "arp_rate": 4,
		"lead": "driving", "pad": false, "drums": "drive", "lead_wave": "square", "lead_duty": 0.5, "level": 0.85, "seed": 21},
	&"fight_2": {"root": 49, "scale": "harmonic", "bpm": 136, "bars": 16, "chords": [0, 5, 3, 4, 0, 5, 6, 4], "bass": "walk", "arp": "updown", "arp_rate": 4,
		"lead": "driving", "pad": false, "drums": "drive", "lead_wave": "square", "lead_duty": 0.25, "level": 0.85, "seed": 22},
	&"fight_3": {"root": 53, "scale": "phrygian", "bpm": 144, "bars": 16, "chords": [0, 1, 0, 6, 0, 1, 5, 4], "bass": "root8", "arp": "broken", "arp_rate": 4,
		"lead": "driving", "pad": true, "drums": "boss", "lead_wave": "saw", "level": 0.9, "seed": 23},
	&"boss": {"root": 50, "scale": "harmonic", "bpm": 152, "bars": 16, "chords": [0, 0, 5, 5, 3, 3, 4, 4], "bass": "root8", "arp": "updown", "arp_rate": 4,
		"lead": "driving", "pad": true, "drums": "boss", "lead_wave": "saw", "level": 0.95, "seed": 31},
	&"finale": {"root": 57, "scale": "minor", "bpm": 108, "bars": 16, "chords": [0, 5, 6, 2, 0, 5, 6, 4], "bass": "long", "arp": "up", "arp_rate": 4,
		"lead": "flowing", "pad": true, "drums": "soft", "lead_wave": "triangle", "level": 0.85, "seed": 32},
	&"victory": {"root": 60, "scale": "major", "bpm": 120, "bars": 8, "chords": [0, 3, 4, 0, 5, 3, 4, 0], "bass": "root8", "arp": "up", "arp_rate": 4,
		"lead": "flowing", "pad": true, "drums": "soft", "lead_wave": "square", "lead_duty": 0.5, "level": 0.85, "seed": 41},
	&"defeat": {"root": 55, "scale": "minor", "bpm": 56, "bars": 8, "chords": [0, 5, 3, 4], "bass": "long", "arp": "none", "arp_rate": 2,
		"lead": "sparse", "pad": true, "drums": "none", "lead_wave": "triangle", "level": 0.75, "seed": 42},
	&"credits": {"root": 55, "scale": "major", "bpm": 76, "bars": 16, "chords": [0, 4, 5, 3, 0, 4, 1, 3], "bass": "long", "arp": "updown", "arp_rate": 2,
		"lead": "sparse", "pad": true, "drums": "none", "lead_wave": "triangle", "level": 0.75, "seed": 51},
	&"shop": {"root": 50, "scale": "dorian", "bpm": 100, "bars": 16, "chords": [0, 3, 4, 0, 5, 3, 1, 4], "bass": "pulse", "arp": "broken", "arp_rate": 2,
		"lead": "sparse", "pad": false, "drums": "soft", "lead_wave": "square", "lead_duty": 0.125, "level": 0.7, "seed": 52},
}
