function md5hash = uq_javaHashString(SInput, method)
import java.security.*;
import java.math.*;
import java.lang.String;

if nargin < 2
    method = 'MD5';
end

%% CREATE THE HASH
persistent md5;
if isempty(md5)
    md5 = MessageDigest.getInstance(method);
end
hash = md5.digest(SInput);
bi = BigInteger(1, hash);
md5hash = char(String.format('%032x', bi));

