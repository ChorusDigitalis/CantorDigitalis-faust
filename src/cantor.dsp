/*
Input parameters are defined first, then the structure of the paper is followed,
with most definitions corresponding to a definition in the paper
*/

import("stdfaust.lib");


// Input parameters:

// Pitch (MIDI value in semitones)
// Note: the pitch range has been chosen to be fairly large here,
// to make extreme effects possible (e.g. hearing individual glottal impulses).
P = hslider("Pitch", 62, -20, 90, 0.01) : si.smoo;
// Vocal effort (between 0 and 1)
E = hslider("Vocal effort", 0.5, 0, 1, 0.01) : si.smoo;
// Vowel height
H = hslider("Vowel height", 0.5, 0, 1, 0.01) : si.smoo;
// Vowel backness
V = hslider("Vowel backness", 0.5, 0, 1, 0.01) : si.smoo;
// Roughness (mapped exponentially)
R = 10^(0 - 5 * (1 - hslider("Roughness", 0.4, 0, 1, 0.01))) : si.smoo;
// Breathiness
B = hslider("Breathiness", 0.1, 0, 1, 0.01) : si.smoo;
// Tenseness
T = hslider("Tenseness", 0.5, 0, 1, 0.01) : si.smoo;
// Vocal tract size
S = hslider("Vocal tract size", 0.5, 0, 1, 0.01) : si.smoo;
// Laryngeal vibration mechanism (M = 1 or 2)
M = hslider("Mechanism", 1, 1, 2, 1) : si.smoo;


// Individual formant gains
G1 = hslider("Formant 1 gain", 1, 0, 1, 0.01) : si.smoo;
G2 = hslider("Formant 2 gain", 1, 0, 1, 0.01) : si.smoo;
G3 = hslider("Formant 3 gain", 1, 0, 1, 0.01) : si.smoo;
G4 = hslider("Formant 4 gain", 1, 0, 1, 0.01) : si.smoo;
G5 = hslider("Formant 5 gain", 1, 0, 1, 0.01) : si.smoo;
G6 = hslider("Formant 6 gain", 1, 0, 1, 0.01) : si.smoo;



// 3. Parametric formant synthesizer
//===================================
// 3.1 Formant synthesizer architecture
//--------------------------------------

process = Gprime : Vtract : BQ;

// Glottal Flow Derivative Model
Gprime = (ba.pulse(ma.SR/f0) : GF : ST) <: (_, _ * Noise) : + ;




// 3.2 Voice source model
//------------------------

// 3.2.2 Glottal formant

// We highpass the output at 20 Hz to remove the continuous component,
// as is done in the Max/MSP code
GF = fi.iir((b0,b1,b2),(a1,a2)) : fi.highpass(2, 20)
with
{
    a1 = -2*exp(0-ma.PI*Bg/ma.SR)*cos(2*ma.PI*Fg/ma.SR);
    a2 = exp(0-2*ma.PI*Bg/ma.SR);
    b0 = 0;
    b1 = Ag;
    b2 = -Ag;
};

// 3.2.3 Spectral tilt

ST = fi.iir(b01,a11) : fi.iir(b02,a12)
with
{
    a11 = 0-(v1 - sqrt(v1^2 - 1));
    a12 = 0-(v2 - sqrt(v2^2 - 1));
    b01 = 1 - 1/(v1 + sqrt(v1^2 - 1));
    b02 = 1 - (v2 - sqrt(v2^2 - 1));

    // We add epsilon to the denominator to prevent against division by zero
    v1 = 1 - (cos(2*ma.PI*3000/ma.SR) - 1) / (10^(Tl1/10) - 1 + ma.EPSILON);
    v2 = 1 - (cos(2*ma.PI*3000/ma.SR) - 1) / (10^(Tl2/10) - 1 + ma.EPSILON);
};


// 3.2.4 Unvoiced source component

Noise = An * no.gnoise(3) : NS;

NS = fi.bandpass(1, 1000, 6000);


// 3.3 Vocal tract model
//-----------------------

Vtract = _ <: (G1*R1, G2*R2, G3*R3, G4*R4, G5*R5, G6*R6) :> _;

// 3.3.1 Vocal tract resonances

Ri(Ai, Bi, Fi) = fi.iir((b0,b1,b2),(a1,a2))
with
{
    a1 = 0 - 2 * exp(0-ma.PI*Bi/ma.SR) * cos(2*ma.PI*Fi/ma.SR);
    a2 = exp(0-2*ma.PI*Bi/ma.SR);
    b0 = (10^(Ai/10)) * (1-exp(0-ma.PI*Bi/ma.SR));
	b1 = 0;
    b2 = (10^(Ai/10)) * (1-exp(0-ma.PI*Bi/ma.SR)) * (0-exp(0-ma.PI*Bi/ma.SR));
};


R1 = Ri(A1, B1, F1);
R2 = Ri(A2, B2, F2);
R3 = Ri(A3, B3, F3);
R4 = Ri(A4, B4, F4);
R5 = Ri(A5, B5, F5);
R6 = Ri(A6, B6, F6);


// 3.3.2 Hypo-pharynx anti-resonances

BQ = (_ / a0) : fi.iir((b0,b1,b2),(a1/a0,a2/a0))
with
{
    a0 = 1 + alphaBQ;
    a1 = betaBQ;
    a2 = 1 - alphaBQ;
    b0 = 1;
    b1 = betaBQ;
    b2 = 1;
	
    alphaBQ = sin(2 * ma.PI * FBQ/ma.SR) / (2 * QBQ);
    betaBQ  = 0 - 2 * cos(2 * ma.PI * FBQ/ma.SR);
};

// 4 Voice dimensions to parameter mapping
//=========================================
// 4.1 Fundamental frequency
//---------------------------

// 4.1.1 Pitch control

// The affine transformation described in the text only applies
// to a specific tablet. To remain generic, we keep controlling pitch
// via its MIDI value instead.

// 4.1.2 Jitter

Jitter = 0.3 * R * no.gnoise(3);

// 4.1.3 Long-term f0 perturbations

pheart = Aheart * os.osccos(4*fc); // TODO get closer to the equation in the text

// damping coefficient (useless for now: no damping yet)
beta = 0.001;
// Heart perturbation amplitude
Aheart = 0.01 * exp(((1-E)/(1-Ethr)) * (log(15)));


f0 = 440 * 2^((P-69)/12) * (1+Jitter); // TODO add pheart and pslow)

// 4.2 Voice source
//------------------

// 4.2.1 Long-term voice amplitude perturbations

Ep = E; // + pheart + pslow; TODO

// Glottal formant frequency
Fg = f0 / (2*Oq);
// Glottal formant bandwidth
Bg = f0 / (Oq * tan(ma.PI*(1-alpham)));

// Open quotient
Oq = (T <= 0.5) * 10^(-2*(1-Oq0)*T) +
     (T >  0.5) * 10^(2*Oq0*(1-T)-1) ;

Oq0 = 0.903 - 0.426 * Ep;

// Asymmetry coefficient
alpham = (T <= 0.5) * (0.5 + 2*(alpham0 - 0.5) * T) +
         (T >  0.5) * (0.9 - 2*(0.9 - alpham0) * (1 - T)) ;

alpham0 = 0.77 - 0.11*M ; // 0.66 if M = 1, 0.55 if M = 2

// 4.2.3 Spectral tilt

// Spectral tilt parameters (in dB)
Tl1 = (9 + 18 * M) - (6   + 15  * M) * Ep;
Tl2 = (2 + 9  * M) - (3.5 + 7.5 * M) * Ep;


// 4.2.4 Voicing amplitude and shimmer

// Phonation threshold
Ethr = 0.2;

Shimmer = 0.3 * R * no.gnoise(3);

// Signal amplitude at phonation threshold
CAg = 0.2;

// Maximum excitation
Ag = phon * ((1-CAg) * (Ep-Ethr)/(1-Ethr) + CAg) * (1+Shimmer) / Oq ; // TODO add NR

// Phonation
phon = ph
    letrec { 'ph = (Ep > (Ethr - 0.05*ph)) ; };


// 4.2.5 Noise amplitude

An = ba.if(phon, B, 1.5 * Ep * B); // TODO check this against Max/MSP code


// 4.3 Vocal tract formants
//--------------------------

// 4.3.1 Generic formant values

// This section's code is slightly messier than the rest.
// The goal is to get from values for vowel height (H) and backness (V)
// to a value for FiG, AiG, BiG, for i from 1 to 6.


// The first step is dividing the vocalic space into 6 rectangular zones
// whose vertices correspond to vowels for which we know the formant parameters.

/*

H=1     +--------+--------+
        | zone 3 | zone 6 |
H=2/3   +--------+--------+
        | zone 2 | zone 5 |
H=1/3   +--------+--------+
        | zone 1 | zone 4 |
H=0     +--------+--------+

       V=0     V=1/2     V=1

*/

vocalic_zone = ba.if
(
    V < 1/2, ba.if(
        H < 1/3, 1, ba.if(
        H < 2/3, 2,
                 3)), // H >= 2/3
    ba.if(
        H < 1/3, 4, ba.if(
        H < 2/3, 5,
                 6)) // H >= 2/3
);

// We also determine where in the rectangle we stand.

normalized_V = (V*2, V*2,   V*2,   V*2-1, V*2-1, V*2-1) : ba.selectn(6, vocalic_zone - 1);
normalized_H = (H*3, H*3-1, H*3-2, H*3,   H*3-1, H*3-2) : ba.selectn(6, vocalic_zone - 1);

// Now we can deduce the values for the formant parameters.
// This is rather cumbersome, so it is done in a separate file.
// Only the parameters of the sixth formant are given here.

import("formant_parameters.lib");

F6G = 2 * F4G; // sixth formant frequency
A6G = -15;     // sixth formant amplitude
B6 = 150;      // sixth formant bandwidth


// 4.3.2 Vocal tract length
alphaS = 1.7 * S + 0.5;

// 4.3.3 Larynx position adaptation to f0

K = 0.000125 * f0 + 0.975;

F3 = K * alphaS * F3G;
F4 = K * alphaS * F4G;
F5 = K * alphaS * F5G;
F6 = K * alphaS * F6G;

// 4.3.4 First formant tuning
F1 = max(f0+50, K*alphaS*F1G + 140/(1-Ethr) - 70);

// 4.3.5 Second formant tuning
F2 = max(2*f0+50, K*alphaS*F2G);

// 4.3.7 Formant amplitudes

// Values of DeltaFi and Attmaxi are not given in the text.
// The following definitions are deduced from the original Max/MSP code.

// Formant i (i = 1, 2, 3) is corrected only when FiG is within DeltaFi of a harmonic
DeltaF1 = 10 + (f0 - 50) * 90  / 1950;
DeltaF2 = 15 + (f0 - 50) * 85  / 1450;
DeltaF3 = 15 + (f0 - 50) * 185 / 1450;

// Maximum attenuation of formant i
Attmax1 = 10 + (f0 - 50) * 15 / 1450;
Attmax2 = 10 + (f0 - 50) * 10 / 1450;
Attmax3 = 20;


// Closest harmonic to a given frequency freq
closest(freq) = ba.if(ma.frac(ratio) <= 0.5, int(ratio), int(ratio)+1)
with
{
    ratio = freq/f0;
};

// Gap between a given frequency freq and the closest harmonic
gap(freq) = abs(freq - closest(freq)*f0);


A1 = ba.if(gap(F1) < DeltaF1,
    A1G - Attmax1 * (1 - gap(F1)/DeltaF1),
    A1G
);

A2 = ba.if(gap(F2) < DeltaF2,
    A2G - Attmax2 * (1 - gap(F2)/DeltaF2),
    A2G
);

A3 = ba.if(gap(F3) < DeltaF3,
    A3G - Attmax3 * (1 - gap(F3)/DeltaF3),
    A3G
);


A4 = A4G;
A5 = A5G;
A6 = A6G;


// 4.3.8 Anti-formants

FBQ = 4700 * alphaS;
QBQ = 2.5;

