# Possible transitions from receive:
#
# * deserialize! - deserialize the request 
#
# * pass! - pass the request to the backend
#
# * error! - return the error code specified, abandoning the request.
#
on :receive do
  deserialize! if request.amf_content?
  pass!
end

# Possible transitions from deserializer:
#
# * pass! - pass the request to the backend
#
# * error! - return the error code specified, abandoning the request.
#
on :deserialize do
  pass!
end

# Possible transitions from pass:
#
# * respond! - pass the request to the backend
#
# * error! - return the error code specified, abandoning the request.
#
on :pass do
  respond!
end

# Possible transitions from respond:
#
# * serialize! - serialize the response
#
# * deliver! - deliver the response upstream
#
# * error! - return the error code specified, abandoning the request.
#
on :respond do
  serialize! if request.amf_content?
  deliver!
end

# Possible transitions from serializer:
#
# * deliver! - deliver the response upstream
#
# * error! - return the error code specified, abandoning the request.
#
on :serialize do
  deliver!
end

# Possible transitions from deliver:
#
# * error! - return the error code specified, abandoning the request.
#
on :deliver do
end

# Possible transitions from deliver:
#
# * error! - return the error code specified, abandoning the request.
#
on :error do
  serialize! if request.amf_content? 
  deliver!
end