const std = @import("std");
const hash = std.crypto.hash;
const testing = std.testing;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
pub const difficulty: usize = 1;
pub const Block = struct {
    //please zls
    Index: i32,
    Coin: i32,
    Hash: [32]u8,
    PrevHash: [32]u8,
    TimeStamp: i64,
    difficulty: usize,
    Nonce: isize,
};

pub const Message = struct { Coin: i32 };

pub var BlockChain = std.ArrayList(Block).init(allocator);

pub fn numToString(n: isize) ![]const u8 {
    var buf: [256]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "{}", .{n});
    return str;
}
pub fn calculateHash(block: Block) ![32]u8 {
    var record: [512]u8 = undefined;
    var stream = std.io.fixedBufferStream(&record);
    var writer = stream.writer();

    try writer.writeAll(try numToString(block.Coin));
    try writer.writeAll(try numToString(block.Index));
    try writer.writeAll(try numToString(block.TimeStamp));
    try writer.writeAll(block.PrevHash[0..]);
    try writer.writeAll(try numToString(block.Nonce));

    var digest: [32]u8 = undefined;
    hash.sha2.Sha256.hash(record[0..], &digest, hash.sha2.Sha256.Options{});
    return digest;
}
//I don't know how to implement channels in zig so this will do;
var channelHash: [32]u8 = undefined;

pub fn isHashValid(
    Hash: [32]u8,
) bool {
    var prefix: [difficulty]u8 = [_]u8{0x0} ** difficulty;
    if (std.mem.eql(u8, Hash[0..difficulty], prefix[0..difficulty])) {
        return true;
    }
    return false;
}

pub fn generateBlock(oldBlock: Block, Coin: i32) !Block {
    const time = std.time.timestamp();
    var newBlock: Block = Block{
        .Index = oldBlock.Index + 1,
        .TimeStamp = time,
        .PrevHash = oldBlock.Hash,
        .Coin = Coin,
        .Hash = undefined,
        .difficulty = difficulty,
        .Nonce = 0,
    };
    while (true) {
        const potentialHash = try calculateHash(newBlock);
        if (isHashValid(potentialHash)) {
            newBlock.Hash = potentialHash;
            channelHash = potentialHash;
            break;
        }
        newBlock.Nonce += 1;
    }
    return newBlock;
}

pub fn isBlockValid(oldBlock: Block, newBlock: Block) !bool {
    if (oldBlock.Index + 1 != newBlock.Index) {
        return false;
    }
    if (!std.mem.eql(u8, oldBlock.Hash[0..], newBlock.PrevHash[0..])) {
        return false;
    }
    if (!std.mem.eql(u8, &channelHash, &newBlock.Hash)) {
        return false;
    }
    return true;
}

pub fn replaceChain(newBlocks: std.ArrayList(Block)) void {
    if (newBlocks.items.len > BlockChain.items.len) {
        BlockChain = newBlocks;
    }
}

test "isHashValid" {
    const testHash: [32]u8 = [_]u8{0} ** 32;
    const isHash = isHashValid(testHash);
    try testing.expectEqual(isHash, true);
}
