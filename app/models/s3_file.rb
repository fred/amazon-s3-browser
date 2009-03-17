require 'logger'

class S3File
  
  # this ACL allows public access
  PUBLIC_GRANT = "READ to AllUsers Group"
  
  ########## GRANTS ##########
  GRANTS = ["READ", "WRITE", "READ_ACP", "WRITE_ACP", "FULL_CONTROL"]
  #
  ######## READ ########
  # when applied to a bucket, grants permission to list the bucket.
  # When applied to an object, this grants permission to read the object data and/or metadata.
  #
  ######## WRITE ########
  # when applied to a bucket, grants permission to create, 
  # overwrite, and delete any object in the bucket.
  # This permission is not supported for objects.
  #
  ####### READ_ACP ########
  # grants permission to read the ACL for the applicable bucket or object.
  # The owner of a bucket or object always has this permission implicitly.
  #
  ####### WRITE_ACP ########
  # gives permission to overwrite the ACP for the applicable bucket or object.
  # The owner of a bucket or object always has this permission implicitly.
  # Granting this permission is equivalent to granting FULL_CONTROL, 
  # because the grant recipient can make any changes to the ACP.
  #
  ######## FULL_CONTROL ########
  # provides READ, WRITE, READ_ACP, and WRITE_ACP permissions.
  # It does not convey additional rights and is provided only for convenience.
  
  
  @config_file = File.join(RAILS_ROOT, 'config/s3_config.yml')
    
  def self.init
    logger = RAILS_DEFAULT_LOGGER
    logger.info("loading S3 variables and connecting...")
    config = File.open(@config_file) { |f| YAML::load(f) }
    @access_key_id = config['aws_access_key']
    @secret_access_key = config['aws_secret_access_key']
    @default_bucket = config['default_bucket']
    if @s3 = AWS::S3::Base.establish_connection!(
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key,
        :persistent => false
      )
      logger.info("...connected to S3")
      logger.info(@s3.inspect)
    else
      logger.info("Could not connect to S3...")
    end
  end
  
  def self.find(object_name, bucket_name=@default_bucket)
    AWS::S3::S3Object.find(object_name, bucket_name)
  end
  

  #  Amazon S3 has only one level of directories, called “buckets”. 
  # There are no subdirectories, so we cannot create folders with the object id
  # for the media_item with id = 137, files will look like this:
  # 137_large_thumb.jpg  137_original.jpg  137_reflection.png  137_small_thumb.jpg
  def upload(bucket,full_path)
    # Just the file name
    base_name = File.basename(full_path)
    # get mime type from file content, using unix command 'file'
    # do not get mime-type from the file name for security reasons.
    # 'file' command is available on most Unix flavors: Linux, OSX, solaris, and BSD
    mime_type = `file -i -p #{full_path}`.chomp.split[1]
    
    message = "Uploading: \n
      localfile: #{local_file} \n 
      as: '#{base_name}' \n
      mime_type '#{mime_type}' \n
      to bucket: '#{params[:id]}'
    "
    logger.info(message)
    AWS::S3::S3Object.store(
      base_name,
      File.open(local_file),
      bucket.name,
      :content_type => mime_type,
      :access => :public_read
    )
  end
  
  # By default authenticated urls expire 5 minutes after they were generated.
  # Expiration options can be specified either with an absolute time 
  # since the epoch with the :expires options, 
  # or with a number of seconds relative to now with the :expires_in options:
  # You can specify whether the url should go over SSL with the :use_ssl option.
  # Example: Expiration relative to now specified in seconds
  #   :expires_in => 60 * 60 * 24
  #     default: 24 hours (86400 seconds)
  def self.private_url(object, options={:expires_in => 86400, :use_ssl => false} )
    AWS::S3::S3Object.url_for(object.key,
      @default_bucket,
      :use_ssl => options[:use_ssl],
      :expires_in => options[:expires_in],
      :authenticated => true
    )
  end

  # the public url is always there, no need to generate public urls.
  # in order to disallow an object to be public readable, 
  # it is necessary to remove this ACL instead: "READ to AllUsers Group"
  def self.public_url(object, options={:use_ssl => false} )
     AWS::S3::S3Object.url_for(object.key,
       @default_bucket,
       :use_ssl => options[:use_ssl],
       :authenticated => false
     )
    #server = "http://s3.amazonaws.com"
    #url = server + object.path
  end

  def self.set_control_cache(object)
    time = Time.parse(object.about["last_modified"])
    object.about[:expires] = (time+259200).httpdate
    object.save
  end
  
  def self.add_public_acl(object)
    policy = object.acl
    policy.grants << AWS::S3::ACL::Grant.grant(:public_read)
    result = AWS::S3::S3Object.acl(object.key, @default_bucket, policy)
    # returns true if the response is OK (200)
    # #<Net::HTTPOK 200 OK readbody=true>
    result.response.code == "200"
  end
  
  def self.set_private_only(object)
    policy = object.acl
    
    # Create an empty Grant
    grant = AWS::S3::ACL::Grant.new
    grant.permission= 'FULL_CONTROL'
    
    # Create an empty Grantee (user to be granted)
    grantee = AWS::S3::ACL::Grantee.new

    # Set grantee to User of Amazon (myself)
    grantee.type = "CanonicalUser"
    # and set the user id of the owner of the object
    grantee.id = object.owner.attributes["id"]
    
    # Associate grantee to the grant
    grant.grantee = grantee
    
    # set only one policy, the owner with full_control
    policy.grants = [grant]
    
    object.acl(policy)
    
    # the defult grant is the owner grant,
    # grants = object.acl.grants
    # grant = object.acl.grants[0]
    # policy.grants = [grant]
    # result = AWS::S3::S3Object.acl(object.key, @default_bucket, policy)
  end
  
  def self.default_bucket
    @default_bucket
  end
  
end
