class Stream < String
  
  def clear!
    slice! 0..length
  end
  
end