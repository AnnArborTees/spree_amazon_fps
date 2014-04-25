################################################################################ 
#  Copyright 2008-2010 Amazon Technologies, Inc
#  Licensed under the Apache License, Version 2.0 (the "License"); 
#  
#  You may not use this file except in compliance with the License. 
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#  specific language governing permissions and limitations under the License.
################################################################################ 


require 'base64'
require 'cgi'
require 'openssl'

module Amazon
module FPS

#
# Copyright:: Copyright (c) 2009 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
#
# RFC 2104-compliant HMAC signature for request parameters
#  Implements AWS Signature, as per following spec:
#
# In Signature Version 2, string to sign is based on following:
#
#    1. The HTTP Request Method followed by an ASCII newline (%0A)
#    2. The HTTP Host header in the form of lowercase host, followed by an ASCII newline.
#    3. The URL encoded HTTP absolute path component of the URI
#       (up to but not including the query string parameters);
#       if this is empty use a forward '/'. This parameter is followed by an ASCII newline.
#    4. The concatenation of all query string components (names and values)
#       as UTF-8 characters which are URL encoded as per RFC 3986
#       (hex characters MUST be uppercase), sorted using lexicographic byte ordering.
#       Parameter names are separated from their values by the '=' character
#       (ASCII character 61), even if the value is empty.
#       Pairs of parameter and values are separated by the '&' character (ASCII code 38).
#
class SignatureUtils 

  SIGNATURE_KEYNAME = "signature"
''
  HMAC_SHA256_ALGORITHM = "HmacSHA256"
  HMAC_SHA1_ALGORITHM = "HmacSHA1"

  def self.sign_parameters(args)
    string_to_sign = "";
    string_to_sign = calculate_string_to_sign_v2(args)
    return compute_signature(string_to_sign, args[:aws_secret_key],get_algorithm(args[:algorithm]))
  end
  
  # Convert a string into URL encoded form.
  def self.urlencode(plaintext)
    CGI.escape(plaintext.to_s).gsub("+", "%20").gsub("%7E", "~")
  end

  private # All the methods below are private

  def self.calculate_string_to_sign_v2(args)
    parameters = args[:parameters]

    uri = args[:uri] 
    uri = "/" if uri.nil? or uri.empty?
    uri = urlencode(uri).gsub("%2F", "/") 

    verb = args[:verb]
    host = args[:host].downcase


    # exclude any existing Signature parameter from the canonical string
    sorted = (parameters.reject { |k, v| k == SIGNATURE_KEYNAME }).sort
    
    canonical = "#{verb}\n#{host}\n#{uri}\n"
    isFirst = true

    sorted.each { |v|
      if(isFirst) then
        isFirst = false
      else
        canonical << '&'
      end

      canonical << urlencode(v[0])
      unless(v[1].nil?) then
        canonical << '='
        canonical << urlencode(v[1])
      end
    }

    return canonical
  end

  def self.get_algorithm(signature_method) 
    return 'sha256' if (signature_method == HMAC_SHA256_ALGORITHM);
    return 'sha1'
  end

  def self.compute_signature(canonical, aws_secret_key, algorithm = 'sha1')
    digest = OpenSSL::Digest.new(algorithm)
    return Base64.encode64(OpenSSL::HMAC.digest(digest, aws_secret_key, canonical)).chomp
  end

end

end
end

