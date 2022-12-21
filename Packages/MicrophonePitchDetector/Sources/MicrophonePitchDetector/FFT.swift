/*
 * FFT library
 * based on public domain code by John Green <green_jt@vsdec.npt.nuwc.navy.mil>
 * original version is available at
 *   http://hyperarchive.lcs.mit.edu/
 *         /HyperArchive/Archive/dev/src/ffts-for-risc-2-c.hqx
 * ported to Csound by Istvan Varga, 2005
 * ported to Swift by JP Simard, 2022
 */

import CMicrophonePitchDetector
import Darwin

// Since this file was ported from C with many variable names preserved, disable SwiftLint
// swiftlint:disable identifier_name

// MARK: - Init

func swift_zt_fft_init(M: Int) -> zt_fft {
    let utbl = UnsafeMutablePointer<Float>.allocate(capacity: (pow2(M) / 4 + 1))
    swiftfftCosInit(M: M, Utbl: utbl)

    let BRLowCpx = UnsafeMutablePointer<Int16>.allocate(capacity: pow2(M / 2 - 1))
    swiftfftBRInit(M: M, BRLow: BRLowCpx)

    let BRLow = UnsafeMutablePointer<Int16>.allocate(capacity: pow2((M - 1) / 2 - 1))
    swiftfftBRInit(M: M - 1, BRLow: BRLow)
    return zt_fft(
        utbl: utbl,
        BRLow: BRLow,
        BRLowCpx: BRLowCpx
    )
}

// MARK: - Compute

func zt_fft_cpx(fft: inout zt_fft, buf: UnsafeMutablePointer<Float>?, FFTsize: Int, sqrttwo: Float) {
    ffts1(buf, Int32(log2(Double(FFTsize))), fft.utbl, fft.BRLowCpx, sqrttwo)
}

// MARK: - FFT Tables

private func swiftfftCosInit(M: Int, Utbl: UnsafeMutablePointer<Float>) {
    let fftN = pow2(M)
    Utbl[0] = 1.0
    for i in 1..<fftN / 4 {
        Utbl[i] = cos(2.0 * Float.pi * Float(i) / Float(fftN))
    }
    Utbl[fftN / 4] = 0.0
}

private func swiftfftBRInit(M: Int, BRLow: UnsafeMutablePointer<Int16>) {
    let Mroot_1 = M / 2 - 1
    let Nroot_1 = pow2(Mroot_1)
    for i in 0..<Nroot_1 {
        var bitsum = 0
        var bitmask = 1
        for bit in 1...Mroot_1 {
            if i & bitmask != 0 {
                bitsum += Nroot_1 >> bit
            }
            bitmask <<= 1
        }
        BRLow[i] = Int16(bitsum)
    }
}

private func pow2(_ n: Int) -> Int {
    1 << n
}
