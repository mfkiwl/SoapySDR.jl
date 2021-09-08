using SoapySDR
using Test
using Unitful
using Unitful.DefaultSymbols
const dB = u"dB"
using Intervals

const sd = SoapySDR

const hardware = "loopback"

# Load dummy test harness or hardware
if hardware == "loopback"
    # build SoapyLoopback and dlopen it
    include("setup_loopback.jl")
elseif hardware == "rtlsdr"
    using SoapyRTLSDR_jll
else
    error("unknown test hardware")
end


@testset "SoapySDR.jl" begin
@testset "StreamFormat" begin

    # Should not throw
    sd.StreamFormat(sd.SOAPY_SDR_CF64)
    sd.StreamFormat(sd.SOAPY_SDR_CF32)
    sd.StreamFormat(sd.SOAPY_SDR_CS32)
    sd.StreamFormat(sd.SOAPY_SDR_CU32)
    sd.StreamFormat(sd.SOAPY_SDR_CS16)
    sd.StreamFormat(sd.SOAPY_SDR_CU16)
    sd.StreamFormat(sd.SOAPY_SDR_F64)
    sd.StreamFormat(sd.SOAPY_SDR_F32)
    sd.StreamFormat(sd.SOAPY_SDR_S32)
    sd.StreamFormat(sd.SOAPY_SDR_U32)
    sd.StreamFormat(sd.SOAPY_SDR_S16)
    sd.StreamFormat(sd.SOAPY_SDR_U16)
    sd.StreamFormat(sd.SOAPY_SDR_S8)
    sd.StreamFormat(sd.SOAPY_SDR_U8)
    sd.StreamFormat(sd.SOAPY_SDR_CS8)
    sd.StreamFormat(sd.SOAPY_SDR_CU8)
    sd.StreamFormat(sd.SOAPY_SDR_CS12)
    sd.StreamFormat(sd.SOAPY_SDR_CU12)
    sd.StreamFormat(sd.SOAPY_SDR_CS4)
    sd.StreamFormat(sd.SOAPY_SDR_CU4)

    # Should throw
    @test_throws ErrorException sd.StreamFormat("nonsense")
end
@testset "Ranges/Display" begin
    intervalrange = sd.SoapySDRRange(0, 1, 0)
    steprange = sd.SoapySDRRange(0, 1, 0.1)

    intervalrangedb = sd._gainrange(intervalrange)
    steprangedb = sd._gainrange(steprange) #TODO

    intervalrangehz = sd._hzrange(intervalrange)
    steprangehz = sd._hzrange(steprange)

    hztype = typeof(1.0*Hz)

    @test typeof(intervalrangedb) == Interval{Gain{Unitful.LogInfo{:Decibel, 10, 10}, :?, Float64}, Closed, Closed}
    @test typeof(steprangedb) == Interval{Gain{Unitful.LogInfo{:Decibel, 10, 10}, :?, Float64}, Closed, Closed}
    @test typeof(intervalrangehz) == Interval{hztype, Closed, Closed}
    @test typeof(steprangehz) == StepRangeLen{hztype, Base.TwicePrecision{hztype}, Base.TwicePrecision{hztype}}

    io = IOBuffer(read=true, write=true)

    sd.print_hz_range(io, intervalrangehz)
    @test String(take!(io)) == "00..0.001 kHz"
    sd.print_hz_range(io, steprangehz)
    @test String(take!(io)) == "00 Hz:0.0001 kHz:0.001 kHz"
end
@testset "High Level API" begin

    @test length(Devices()) == 1
    dev = Devices()[1]

    @test typeof(dev) == sd.Device
    @test typeof(dev.info) == sd.OwnedKWArgs
    @test dev.driver == :LoopbackDriver
    @test dev.hardware == :LoopbackHardware
    dev.hardwareinfo #TODO
    rx_chan = dev.rx[1]
    tx_chan = dev.tx[1]

    @test typeof(rx_chan) == sd.Channel
    @test typeof(tx_chan) == sd.Channel


    # Test sensor API
    sensor_list = sd.list_sensors(dev)
    @test map(sensor -> sd.read_sensor(dev, sensor), sensor_list) == ["true", "1.0", "1.0"]
    sensor_info_list = map(sensor -> sd.get_sensor_info(dev, sensor), sensor_list)


    # test time API
    time_sources = sd.list_time_sources(dev)
    @test time_sources == ["sw_ticks", "hw_ticks"]
    @test sd.get_time_source(dev) == "sw_ticks"
    sd.set_time_source!(dev, "hw_ticks")
    @test sd.get_time_source(dev) == "hw_ticks"




    @show sd.list_sample_rates(rx_chan)

    #@test gainrange(rx_chan) == 0u"dB"..53u"dB"
    #@test gainrange(tx_chan) == 0u"dB"..53u"dB"
    @show sd.frequency_ranges(rx_chan)
    @show sd.frequency_ranges(tx_chan)
    @show sd.bandwidth_ranges(rx_chan)
    @show sd.bandwidth_ranges(tx_chan)
    @show sd.sample_rate_ranges(rx_chan)
    @show sd.sample_rate_ranges(tx_chan)

    #@show sd.GainElement(rx_chan)
    #@show sd.GainElement(tx_chan)

    # Loopback initialized defaults
    #@test rx_chan.bandwidth == 2.048e6u"Hz"
    #@test rx_chan.frequency == 1.0e8u"Hz"
    #@test rx_chan.gain == -53u"dB"
    #@test rx_chan.sample_rate == 2.048e6u"Hz"
    @show rx_chan.info
    @show rx_chan.antenna
    @show rx_chan.dc_offset_mode
    @show rx_chan.dc_offset
    @show rx_chan.iq_balance_mode
    @show rx_chan.iq_balance
    @show rx_chan.gain_mode
    #@show rx_chan.gain_profile
    @show rx_chan.frequency_correction

    #@test tx_chan.bandwidth == 2.048e6u"Hz"
    #@test tx_chan.frequency == 1.0e8u"Hz"
    #@test tx_chan.gain == -53u"dB"
    #@test tx_chan.sample_rate == 2.048e6u"Hz"

    # setter/getter tests
    rx_chan.sample_rate = 1e5u"Hz"
    #@test rx_chan.sample_rate == 1e5u"Hz"


    rx_stream = sd.Stream(ComplexF32, [rx_chan])

    tx_stream = sd.Stream(ComplexF32, [tx_chan])

end
end
