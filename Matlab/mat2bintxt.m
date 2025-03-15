load('test_signal_1.mat');

dataList = symbole_rx;

n = 4;         % number bits for integer part of your number      
m = 12;         % number bits for fraction part of your number

fileID = fopen('test_signal.txt', 'w');
if fileID == -1
    error('Fehler beim Öffnen der Datei.');
end

for idx = 1:length(symbole_rx) - Lp
    re = real(dataList(idx));
    im = imag(dataList(idx));
    conv_re = 0;
    conv_im = 0;
    if re < 0
        re = -1*re;
        conv_re = 1;
    end

    if im < 0
        im = -1*im;
        conv_im = 1;
    end

    re = [ fix(rem(fix(re)*pow2(-(n-1):0),2)), fix(rem( rem(re,1)*pow2(1:m),2))];
    im = [ fix(rem(fix(im)*pow2(-(n-1):0),2)), fix(rem( rem(im,1)*pow2(1:m),2))];

    if conv_re
        re = 1-re;
        carry = 1;
        for i = length(re):-1:1
            sum_val = re(i) + carry;
            re(i) = mod(sum_val, 2);   
            carry = floor(sum_val/2); 
        end
    end

    if conv_im
        im = 1-im;
        carry = 1;
        for i = length(im):-1:1
            sum_val = im(i) + carry;
            im(i) = mod(sum_val, 2);   
            carry = floor(sum_val/2); 
        end
    end

    re_s = compose("%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",re);
    im_s = compose("%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",im);

    fprintf(fileID, '%s, %s\n', re_s, im_s);
end

fclose(fileID);
