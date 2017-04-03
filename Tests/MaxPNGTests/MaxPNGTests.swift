import Glibc
import MaxPNG

public
typealias RelativePath = String
typealias Unixpath = String

func unix_path(_ path:RelativePath) -> Unixpath
{
    guard path.characters.count > 1
    else
    {
        return path
    }
    let path_i0 = path.startIndex
    let path_i2 = path.index(path_i0, offsetBy: 2)
    var expanded_path:Unixpath = path
    if path[path.startIndex..<path_i2] == "~/"
    {
        expanded_path = String(cString: getenv("HOME")) +
                        path[path.index(path_i0, offsetBy: 1)..<path.endIndex]
    }
    return expanded_path
}

public
func skip_png(_ rpath:RelativePath) throws
{
    let path = unix_path(rpath)
    let _ = try PNGDecoder(path: path, look_for: [])
}

public
func write_png(_ rpath:RelativePath, _ scanlines:[[UInt8]], header:PNGImageHeader) throws
{
    let path = unix_path(rpath)
    let png = try PNGEncoder(path: path, header: header)
    try png.initialize()
    for scanline in scanlines
    {
        try png.add_scanline(scanline)
    }
    try png.finish()
}

public
func reencode_png_stream(_ rpath:RelativePath, output:RelativePath) throws
{
    let path = unix_path(rpath)
    let out = unix_path(output)
    let png_decode = try PNGDecoder(path: path)
    let png_encode = try PNGEncoder(path: out, header: png_decode.header)
    try png_encode.initialize()
    let total_scanlines = png_decode.header.height
    print(png_decode.header)
    var l = 0
    print("0 %")
    while let scanline = try png_decode.next_scanline()
    {
        l += 1
        try png_encode.add_scanline(scanline)
    }
    try png_encode.finish()
    print("100 %")
}

public
func decompose_png(_ rpath:RelativePath, output:RelativePath) throws
{
    let png_decode = try PNGDecoder(path: unix_path(rpath))

    let total_scanlines = png_decode.header.height
    print(png_decode.header)
    var l = 0
    print("0 %")
    var scanlines:[[UInt8]] = []
    scanlines.reserveCapacity(png_decode.header.height)
    while let scanline = try png_decode.next_scanline()
    {
        l += 1
        scanlines.append(scanline)
    }
    print("100 %")

    let out = unix_path(output)
    l = 0
    for (offset: i, element: (width: h, height: k)) in png_decode.header.sub_dimensions.enumerated()
    {
        let frag_header = try PNGImageHeader(width: h, height: k,
                                            bit_depth: png_decode.header.bit_depth,
                                            color_type: png_decode.header.color_type,
                                            interlace: false)
        let png_encode = try PNGEncoder(path: "\(out)_subimage_\(i).png", header: frag_header)
        try png_encode.initialize()
        for (i, scanline) in scanlines[l..<(l + k)].enumerated()
        {
            try png_encode.add_scanline(scanline)
        }
        try png_encode.finish()
        l += k
    }

}
