const std = @import("std");
const zap = @import("zap");
const block = @import("blockchain.zig");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn on_request(r: zap.Request) void {
    if (r.methodAsEnum() == .GET) {
        if (r.path) |the_path| {
            std.debug.print("PATH: {s}\n", .{the_path});
            const blockchain = block.BlockChain.items;
            defer block.BlockChain.deinit();
            var buffer: [10240]u8 = undefined;
            var json_to_send: []const u8 = undefined;
            if (zap.stringifyBuf(&buffer, blockchain, .{})) |json| {
                json_to_send = json;
            } else {
                json_to_send = "null";
            }
            std.debug.print("<< json: {s}\n", .{json_to_send});
            r.setContentType(.JSON) catch return;
            r.setContentTypeFromFilename("test.json") catch return;
            r.sendBody(json_to_send) catch return;
        }
    }
    if (r.methodAsEnum() == .POST) {
        if (r.path) |the_path| {
            std.debug.print("PATH: {s}\n", .{the_path});
            const parsed = std.json.parseFromSlice(block.Message, allocator, r.body.?, .{}) catch return;
            defer parsed.deinit();
            const message = parsed.value;
            const newBlock = block.generateBlock(block.BlockChain.getLast(), message.Coin) catch return;
            if (block.isBlockValid(block.BlockChain.getLast(), newBlock) catch return) {
                block.BlockChain.append(newBlock) catch return;
                block.replaceChain(block.BlockChain);
            }
            const blockchain = block.BlockChain.items;
            std.debug.print("<< blockchain: {d}\n", .{blockchain.len});
            var buffer: [10240000]u8 = undefined;
            var json_to_send: []const u8 = undefined;
            if (zap.stringifyBuf(&buffer, blockchain, .{})) |json| {
                json_to_send = json;
            } else {
                json_to_send = "null";
            }
            std.debug.print("<< json: {s}\n", .{json_to_send});
            r.setContentType(.JSON) catch return;
            r.setContentTypeFromFilename("test.json") catch return;
            r.sendBody(json_to_send) catch return;
        }
    }
}

pub fn main() !void {
    const emptyHash: [32]u8 = [_]u8{0} ** 32;
    const time = std.time.timestamp();
    const genesisBlock = block.Block{
        //please zls formatter don't be stupid
        .Index = 0,
        .Coin = 0,
        .TimeStamp = time,
        .Hash = emptyHash,
        .PrevHash = emptyHash,
    };
    try block.BlockChain.append(genesisBlock);

    var listener = zap.HttpListener.init(.{
        .port = 6969,
        .on_request = on_request,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:6969\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
