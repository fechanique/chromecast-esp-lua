chromecastIp = "192.168.1.139"
port = 8009
appId = "AF34CB76"

function composeMessage(namespace, payload)
  return string.char(0x08,0x00) --protocol_version = 0
  ..string.char(0x12,0x08) .. 'sender-0'
  ..string.char(0x1a,0x0a) .. 'receiver-0'
  ..string.char(0x22, #namespace) .. namespace
  ..string.char(0x28,0x00) -- payload_type = 0 (STRING)
  ..string.char(0x32, #payload) .. payload
end

function sendProtobufMessage(conn, message)
    local body = message
    local length = #body
    -- Convertimos length a 4 bytes big-endian
    local b1 = bit.rshift(bit.band(length,0xFF000000),24)
    local b2 = bit.rshift(bit.band(length,0x00FF0000),16)
    local b3 = bit.rshift(bit.band(length,0x0000FF00),8)
    local b4 = bit.band(length,0x000000FF)
    local header = string.char(b1, b2, b3, b4)
    conn:send(header .. body)
end

conn = tls.createConnection()
conn:on("connection", function(sck)
    print("Conectado al Chromecast")
    sendProtobufMessage(sck, composeMessage('urn:x-cast:com.google.cast.tp.connection', '{"type":"CONNECT"}'))
    tmr.create():alarm(5000, tmr.ALARM_AUTO, function()
        sendProtobufMessage(sck, composeMessage('urn:x-cast:com.google.cast.tp.heartbeat', '{"type":"PING"}'))
    end)
    --sendProtobufMessage(sck, getStatusMessage)
    --sendProtobufMessage(sck, launchMessageBody)
end)

conn:on("receive", function(sck, data)
    print("Recibido:", data)
end)

conn:on("disconnection", function(sck)
    print("ConexiÃ³n cerrada")
end)

gpio.mode(3, gpio.INPUT)
gpio.trig(3, 'up', function(l) 
    sendProtobufMessage(conn, composeMessage('urn:x-cast:com.google.cast.receiver', '{"type":"LAUNCH","appId":"'..appId..'","requestId":1}'))
end)

conn:connect(port, chromecastIp)
