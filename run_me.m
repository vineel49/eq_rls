% linear equalizer based on RLS
clear all
close all
clc
training_len = 10^4;% length of the training sequence
snr_dB = 10; % SNR in dB
equalizer_len = 30; % length of the equalizer
f_fac = 0.999; % forgetting factor
data_len = 10^5; % length of the data sequence
delta = 100; % value to initialize P(0)

% SNR parameters
snr = 10^(0.1*snr_dB);
noise_var = 1/(2*snr); % noise variance
% ---------          training phase       --------------------------------
% source
training_a = randi([0 1],1,training_len);
% bpsk mapper (bit '0' maps to 1 and bit '1' maps to -1)
training_seq = 1-2*training_a;
% isi channel
fade_chan = [0.9 0.1 0.1 -0.1 ]; % impulse response of the ISI channel
fade_chan = fade_chan/norm(fade_chan);
chan_len = length(fade_chan);
% noise
noise = normrnd(0,sqrt(noise_var),1,training_len+chan_len-1);
% channel output
chan_op = conv(fade_chan,training_seq)+noise;
%     RLS algorithm
equalizer = zeros(equalizer_len,1);
P_matrix = delta*eye(equalizer_len,equalizer_len);

for i1 = 1:training_len-equalizer_len+1
    equalizer_ip = transpose(fliplr(chan_op(i1:i1+equalizer_len-1)));
    alpha = training_seq(i1+equalizer_len-1)-equalizer_ip.'*equalizer;
    g = P_matrix*equalizer_ip/(f_fac+equalizer_ip.'*P_matrix*equalizer_ip);
    P_matrix = (1/f_fac)*P_matrix-g*equalizer_ip.'*(1/f_fac)*P_matrix;
    equalizer = equalizer+alpha*g;
end
equalizer = equalizer.'; % now a row vector


%------------------ data transmission phase----------------------------
% source
data_a = randi([0 1],1,data_len);
% bpsk mapper (bit '0' maps to 1 and bit '1' maps to -1)
data_seq = 1-2*data_a;
% AWGN
noise = normrnd(0,sqrt(noise_var),1,data_len+chan_len-1);
% channel output
chan_op = conv(fade_chan,data_seq)+noise;
% equalization
equalizer_op = conv(chan_op,equalizer);
equalizer_op = equalizer_op(1:data_len);
% demapping symbols back to bits
dec_a = equalizer_op<0;
% bit error rate
ber = nnz(dec_a-data_a)/data_len
