function y=rms_sig(x)

y=sqrt((1/length(x))*sum(x.^2));

end