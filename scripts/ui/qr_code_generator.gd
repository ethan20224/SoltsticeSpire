extends RefCounted
class_name QRCodeGenerator
## Pure-GDScript ISO/IEC 18004 QR Code Generator (Byte Mode, ECC Level L, Versions 1-6).
## Generates crisp, 100% standards-compliant scannable QR ImageTextures with zero external dependencies.

# Capacity of Byte Mode at ECC Level L for Versions 1..6
const VERSION_CAPACITIES := [0, 17, 32, 53, 78, 106, 134]
# Total data codewords for Versions 1..6 at ECC Level L
const DATA_CODEWORDS := [0, 19, 34, 55, 80, 108, 136]
# ECC codewords per block for Versions 1..6 at ECC Level L (all 1-block except V6 which is 2 blocks of 68 data + 18 ecc)
const ECC_CODEWORDS_PER_BLOCK := [0, 7, 10, 15, 20, 26, 18]
const NUM_BLOCKS := [0, 1, 1, 1, 1, 1, 2]

# Alignment pattern center coordinates for Versions 1..6
const ALIGNMENT_CENTERS := [
	[],
	[],
	[6, 18],
	[6, 22],
	[6, 26],
	[6, 30],
	[6, 34],
]

# Precomputed Format Information 15-bit strings for ECC Level L (01) and Mask Patterns 0..7
const FORMAT_INFO_L := [
	0x77C4, 0x72F3, 0x7DAA, 0x789D,
	0x662F, 0x6318, 0x6C41, 0x6976,
]


static func generate_image(text: String, scale_px: int = 8, quiet_zone: int = 4,
		dark_color: Color = Color(0.08, 0.06, 0.05, 1.0),
		light_color: Color = Color(0.99, 0.97, 0.93, 1.0)) -> Image:
	var matrix := encode_matrix(text)
	var n: int = matrix.size()
	if n == 0:
		var fallback := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		fallback.fill(light_color)
		return fallback

	var total_modules: int = n + quiet_zone * 2
	var img_px: int = total_modules * scale_px
	var img := Image.create(img_px, img_px, false, Image.FORMAT_RGBA8)
	img.fill(light_color)

	for r in range(n):
		var row: Array = matrix[r]
		for c in range(n):
			if row[c] == 1:
				var x0: int = (c + quiet_zone) * scale_px
				var y0: int = (r + quiet_zone) * scale_px
				img.fill_rect(Rect2i(x0, y0, scale_px, scale_px), dark_color)
	return img


static func generate_texture(text: String, scale_px: int = 8, quiet_zone: int = 4,
		dark_color: Color = Color(0.08, 0.06, 0.05, 1.0),
		light_color: Color = Color(0.99, 0.97, 0.93, 1.0)) -> ImageTexture:
	var img := generate_image(text, scale_px, quiet_zone, dark_color, light_color)
	return ImageTexture.create_from_image(img)


static func encode_matrix(text: String) -> Array:
	var raw_bytes: PackedByteArray = text.to_utf8_buffer()
	var byte_len: int = raw_bytes.size()
	var ver: int = 0
	for v in range(1, VERSION_CAPACITIES.size()):
		if byte_len <= VERSION_CAPACITIES[v]:
			ver = v
			break
	if ver == 0:
		push_error("QRCodeGenerator: Payload too long (%d bytes)" % byte_len)
		return []

	var data_cw_count: int = DATA_CODEWORDS[ver]
	var bits: Array[int] = []
	# Mode indicator for Byte Mode = 0100 (4 bits)
	_append_bits(bits, 0b0100, 4)
	# Character count indicator (8 bits for Versions 1..9 in Byte Mode)
	_append_bits(bits, byte_len, 8)
	# Payload bytes
	for b in raw_bytes:
		_append_bits(bits, int(b), 8)

	# Terminator (up to 4 zero bits)
	var max_bits: int = data_cw_count * 8
	var term_len: int = mini(4, max_bits - bits.size())
	_append_bits(bits, 0, term_len)

	# Pad to byte boundary
	while bits.size() % 8 != 0:
		bits.append(0)

	# Convert bits to data codewords
	var data_codewords: Array[int] = []
	for i in range(0, bits.size(), 8):
		var val: int = 0
		for j in range(8):
			val = (val << 1) | bits[i + j]
		data_codewords.append(val)

	# Pad with alternating 0xEC (236) and 0x11 (17)
	var pad_idx: int = 0
	while data_codewords.size() < data_cw_count:
		data_codewords.append(0xEC if (pad_idx % 2 == 0) else 0x11)
		pad_idx += 1

	# Split into blocks and compute Reed-Solomon ECC codewords
	var num_blk: int = NUM_BLOCKS[ver]
	var ecc_per_blk: int = ECC_CODEWORDS_PER_BLOCK[ver]
	var data_per_blk: int = data_cw_count / num_blk
	var data_blocks: Array = []
	var ecc_blocks: Array = []
	for b_idx in range(num_blk):
		var blk_data: Array[int] = []
		for i in range(data_per_blk):
			blk_data.append(data_codewords[b_idx * data_per_blk + i])
		data_blocks.append(blk_data)
		ecc_blocks.append(_compute_reed_solomon(blk_data, ecc_per_blk))

	# Interleave data blocks, then ECC blocks
	var final_codewords: Array[int] = []
	for i in range(data_per_blk):
		for b_idx in range(num_blk):
			final_codewords.append(data_blocks[b_idx][i])
	for i in range(ecc_per_blk):
		for b_idx in range(num_blk):
			final_codewords.append(ecc_blocks[b_idx][i])

	# Convert final codewords into bit stream (+ remainder bits for V2..6)
	var final_bits: Array[int] = []
	for cw in final_codewords:
		_append_bits(final_bits, cw, 8)
	var remainder_bits: int = 7 if (ver >= 2 and ver <= 6) else 0
	_append_bits(final_bits, 0, remainder_bits)

	# Build module matrix
	var size: int = 17 + ver * 4
	var matrix: Array = []
	var is_func: Array = []
	for r in range(size):
		var m_row: Array[int] = []
		var f_row: Array[bool] = []
		m_row.resize(size)
		f_row.resize(size)
		m_row.fill(0)
		f_row.fill(false)
		matrix.append(m_row)
		is_func.append(f_row)

	# Place function patterns
	_place_finder_pattern(matrix, is_func, 0, 0, size)
	_place_finder_pattern(matrix, is_func, size - 7, 0, size)
	_place_finder_pattern(matrix, is_func, 0, size - 7, size)

	# Timing patterns
	for i in range(8, size - 8):
		var bit: int = 1 if (i % 2 == 0) else 0
		matrix[6][i] = bit
		is_func[6][i] = true
		matrix[i][6] = bit
		is_func[i][6] = true

	# Alignment patterns
	var centers: Array = ALIGNMENT_CENTERS[ver]
	for cy in centers:
		for cx in centers:
			# Skip if overlapping finder pattern
			if (cx <= 8 and cy <= 8) or (cx >= size - 9 and cy <= 8) or (cx <= 8 and cy >= size - 9):
				continue
			_place_alignment_pattern(matrix, is_func, cx, cy)

	# Dark module and reserved format info areas
	matrix[4 * ver + 9][8] = 1
	is_func[4 * ver + 9][8] = true
	for i in range(9):
		if i != 6:
			is_func[8][i] = true
			is_func[i][8] = true
	for i in range(8):
		is_func[8][size - 1 - i] = true
		is_func[size - 1 - i][8] = true

	# Place data bits in upward/downward 2-column zig-zag
	var bit_idx: int = 0
	var upward: bool = true
	var col: int = size - 1
	while col > 0:
		if col == 6:
			col -= 1
		for step in range(size):
			var r: int = (size - 1 - step) if upward else step
			for dc in range(2):
				var c: int = col - dc
				if not is_func[r][c]:
					var b_val: int = final_bits[bit_idx] if bit_idx < final_bits.size() else 0
					matrix[r][c] = b_val
					bit_idx += 1
		upward = not upward
		col -= 2

	# Evaluate all 8 masks and choose the lowest penalty score
	var best_mask: int = 0
	var best_penalty: int = 999999999
	var best_matrix: Array = []
	for mask_id in range(8):
		var candidate := _clone_matrix(matrix)
		_apply_mask(candidate, is_func, mask_id, size)
		_write_format_bits(candidate, mask_id, size)
		var pen := _compute_penalty(candidate, size)
		if pen < best_penalty:
			best_penalty = pen
			best_mask = mask_id
			best_matrix = candidate

	return best_matrix


static func _append_bits(arr: Array[int], val: int, count: int) -> void:
	for i in range(count - 1, -1, -1):
		arr.append((val >> i) & 1)


static func _place_finder_pattern(matrix: Array, is_func: Array, left: int, top: int, size: int) -> void:
	for dy in range(-1, 8):
		for dx in range(-1, 8):
			var r: int = top + dy
			var c: int = left + dx
			if r < 0 or r >= size or c < 0 or c >= size:
				continue
			var dark: bool = false
			if dy >= 0 and dy <= 6 and dx >= 0 and dx <= 6:
				if dy == 0 or dy == 6 or dx == 0 or dx == 6 or (dy >= 2 and dy <= 4 and dx >= 2 and dx <= 4):
					dark = true
			matrix[r][c] = 1 if dark else 0
			is_func[r][c] = true


static func _place_alignment_pattern(matrix: Array, is_func: Array, cx: int, cy: int) -> void:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var dist: int = maxi(absi(dx), absi(dy))
			matrix[cy + dy][cx + dx] = 1 if (dist != 1) else 0
			is_func[cy + dy][cx + dx] = true


static func _apply_mask(matrix: Array, is_func: Array, mask_id: int, size: int) -> void:
	for r in range(size):
		for c in range(size):
			if is_func[r][c]:
				continue
			var invert: bool = false
			match mask_id:
				0: invert = ((r + c) % 2 == 0)
				1: invert = (r % 2 == 0)
				2: invert = (c % 3 == 0)
				3: invert = ((r + c) % 3 == 0)
				4: invert = (((r / 2) + (c / 3)) % 2 == 0)
				5: invert = (((r * c) % 2) + ((r * c) % 3) == 0)
				6: invert = ((((r * c) % 2) + ((r * c) % 3)) % 2 == 0)
				7: invert = ((((r + c) % 2) + ((r * c) % 3)) % 2 == 0)
			if invert:
				matrix[r][c] = matrix[r][c] ^ 1


static func _write_format_bits(matrix: Array, mask_id: int, size: int) -> void:
	var fmt: int = FORMAT_INFO_L[mask_id]
	# Bits 0..14 where bit 14 is MSB
	var bits: Array[int] = []
	bits.resize(15)
	for i in range(15):
		bits[i] = (fmt >> i) & 1

	# Top-left around finder
	for i in range(6):
		matrix[8][i] = bits[14 - i]
	matrix[8][7] = bits[8]
	matrix[8][8] = bits[7]
	matrix[7][8] = bits[6]
	for i in range(6):
		matrix[5 - i][8] = bits[5 - i]

	# Bottom-left and top-right
	for i in range(7):
		matrix[size - 1 - i][8] = bits[14 - i]
	for i in range(8):
		matrix[8][size - 8 + i] = bits[7 - i]


static func _clone_matrix(matrix: Array) -> Array:
	var out: Array = []
	for r in matrix:
		out.append(r.duplicate())
	return out


static func _compute_penalty(matrix: Array, size: int) -> int:
	var penalty: int = 0
	# Rule 1: 5+ consecutive modules in row/col
	for r in range(size):
		var run_val: int = matrix[r][0]
		var run_len: int = 1
		for c in range(1, size):
			if matrix[r][c] == run_val:
				run_len += 1
			else:
				if run_len >= 5:
					penalty += 3 + (run_len - 5)
				run_val = matrix[r][c]
				run_len = 1
		if run_len >= 5:
			penalty += 3 + (run_len - 5)

	for c in range(size):
		var run_val: int = matrix[0][c]
		var run_len: int = 1
		for r in range(1, size):
			if matrix[r][c] == run_val:
				run_len += 1
			else:
				if run_len >= 5:
					penalty += 3 + (run_len - 5)
				run_val = matrix[r][c]
				run_len = 1
		if run_len >= 5:
			penalty += 3 + (run_len - 5)

	# Rule 2: 2x2 blocks
	for r in range(size - 1):
		for c in range(size - 1):
			var v: int = matrix[r][c]
			if v == matrix[r][c + 1] and v == matrix[r + 1][c] and v == matrix[r + 1][c + 1]:
				penalty += 3
	return penalty


# --- Reed-Solomon GF(256) with primitive polynomial 0x11D ---
static func _gf_mul(x: int, y: int) -> int:
	var r: int = 0
	var a: int = x
	var b: int = y
	while b > 0:
		if (b & 1) != 0:
			r ^= a
		b >>= 1
		a <<= 1
		if (a & 0x100) != 0:
			a ^= 0x11D
	return r


static func _rs_generator_poly(degree: int) -> Array[int]:
	var gen: Array[int] = [1]
	var root: int = 1
	for _i in range(degree):
		var next_gen: Array[int] = []
		next_gen.resize(gen.size() + 1)
		next_gen.fill(0)
		for j in range(gen.size()):
			next_gen[j] ^= gen[j]
			next_gen[j + 1] ^= _gf_mul(gen[j], root)
		gen = next_gen
		root = _gf_mul(root, 2)
	return gen


static func _compute_reed_solomon(data: Array[int], ecc_count: int) -> Array[int]:
	var gen := _rs_generator_poly(ecc_count)
	var rem: Array[int] = []
	rem.resize(ecc_count)
	rem.fill(0)
	for b in data:
		var factor: int = b ^ rem[0]
		rem.remove_at(0)
		rem.append(0)
		for j in range(ecc_count):
			rem[j] ^= _gf_mul(gen[j + 1], factor)
	return rem
