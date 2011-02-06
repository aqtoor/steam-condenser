# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2008-2011, Sebastian Staudt

require 'datagram_channel'
require 'ipaddr'
require 'stringio_additions'
require 'exceptions/timeout_exception'

# This module defines common methods for sockets used to connect to game and
# master servers.
#
# @author Sebastian Staudt
# @see GoldSrcSocket
# @see MasterServerSocket
# @see RCONSocket
# @see SourceSocket
# @since sdds
module SteamSocket

  # The default timeout
  # @since 0.11.0
  @@timeout = 1000

  # Sets the timeout for socket operations. This usually only affects timeouts,
  # i.e. when a server does not respond in time.
  #
  # Due to the server-side implementation of the RCON protocol, each RCON
  # request will also wait this amount of time after execution. So if you need
  # RCON requests to execute fast, you should set this to a adequatly low
  # value.
  #
  # +timeout+ The amount of milliseconds before a request times out
  def self.timeout=(timeout)
    @@timeout = timeout
  end

  def initialize(*args)
    @channel = DatagramChannel.open
    @channel.connect(*args)

    @remote_socket = Socket.getaddrinfo args[0].to_s, args[1]
  end

  # Closes the underlying channel
  def close
    @channel.close
  end

  # Abstract +reply+ method
  def reply
    raise NotImplementedError
  end

  def receive_packet(buffer_length = 0)
    if select([@channel.socket], nil, nil, @@timeout / 1000.0).nil?
      raise TimeoutException
    end

    if buffer_length == 0
      @buffer.rewind
    else
      @buffer = StringIO.allocate buffer_length
    end

    bytes_read = @channel.read @buffer
    @buffer.rewind

    bytes_read
  end

  def send(data_packet)
    puts "Sending data packet of type \"#{data_packet.class.to_s}\"." if $DEBUG

    @buffer = StringIO.new data_packet.to_s
    @channel.write @buffer
  end

end
