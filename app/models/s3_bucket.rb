require 'logger'

class S3Bucket

  # If you plan on always using a specific bucket for certain files, 
  # you can skip always having to specify the bucket by creating 
  # a subclass of Bucket or S3Object and telling it what bucket to use.
  class Theultralounge < AWS::S3::S3Object
    set_current_bucket_to(S3File.default_bucket)
  end
  

  def self.list
    AWS::S3::Bucket.list
  end
    
  def self.list_objects(bucket_name=S3File.default_bucket)
    @bucket = AWS::S3::Bucket.find(bucket_name)
    @files = @bucket.objects
  end
  
  def self.find(bucket_name=S3File.default_bucket)
    @bucket = AWS::S3::Bucket.find(bucket_name)
  end
  
end
