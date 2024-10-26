const std = @import("std");
const hash = std.crypto.hash;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
pub const Block = struct {
    //please zls
    Index: i32,
    Coin: i32,
    Hash: [32]u8,
    PrevHash: [32]u8,
    TimeStamp: i64,
};

pub const Message = struct { Coin: i32 };

pub var BlockChain = std.ArrayList(Block).init(allocator);

pub fn numToString(n: isize) ![]const u8 {
    var buf: [256]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "{}", .{n});
    return str;
}
fn calculateHash(block: Block) ![32]u8 {
    var record: [512]u8 = undefined;
    var stream = std.io.fixedBufferStream(&record);
    var writer = stream.writer();

    try writer.writeAll(try numToString(block.Coin));
    try writer.writeAll(try numToString(block.Index));
    try writer.writeAll(try numToString(block.TimeStamp));
    try writer.writeAll(block.PrevHash[0..]);

    var digest: [32]u8 = undefined;
    hash.sha2.Sha256.hash(record[0..], &digest, hash.sha2.Sha256.Options{});
    return digest;
}

pub fn timestampToBytes(timestamp: i64) ![256]u8 {
    var buffer: [256]u8 = undefined;
    _ = try std.fmt.bufPrint(&buffer, "{}", .{timestamp});
    return buffer;
}

pub fn generateBlock(oldBlock: Block, Coin: i32) !Block {
    const time = std.time.timestamp();
    var newBlock: Block = Block{
        .Index = oldBlock.Index + 1,
        .TimeStamp = time,
        .PrevHash = oldBlock.Hash,
        .Coin = Coin,
        .Hash = undefined,
    };
    newBlock.Hash = try calculateHash(newBlock);
    return newBlock;
}

pub fn isBlockValid(oldBlock: Block, newBlock: Block) !bool {
    if (oldBlock.Index + 1 != newBlock.Index) {
        return false;
    }
    if (!std.mem.eql(u8, oldBlock.Hash[0..], newBlock.PrevHash[0..])) {
        return false;
    }
    const newHash = try calculateHash(newBlock);
    if (!std.mem.eql(u8, newHash[0..], newBlock.Hash[0..])) {
        return false;
    }
    return true;
}

pub fn replaceChain(newBlocks: std.ArrayList(Block)) void {
    if (newBlocks.items.len > BlockChain.items.len) {
        BlockChain = newBlocks;
    }
}
