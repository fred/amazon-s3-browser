class S3BucketsController < ApplicationController

  def index
    @crumbs = [ 'Buckets' ]
    @buckets = S3Bucket.list
  end
  
  def show
    @crumbs = [ 'Buckets', params[:id] ]
    @bucket = S3Bucket.find(params[:id])
    @files = @bucket.objects
  end
  
  def upload
    @crumbs = [ 'Buckets', params[:id], "Upload Files" ]
    @bucket = S3Bucket.find(params[:id])
  end
  
  def upload_from_url
    local_file = params[:filepath].to_s
    
    @bucket = S3Bucket.find(params[:id])
    
    if S3file.upload(@bucket, local_file)
      flash[:notice] = "File Uploaded: #{local_file}"
    else
      flash[:notice] = "Error. File not uploaded."
    end
    redirect_to :action => "upload"
  end
  
  
  def upload_submit
  end
  
  def new
    @crumbs = [ 'New Bucket' ]
    @bucket = AWS::S3::Bucket.new
  end
  
  def create
    if params[:name] && AWS::S3::Bucket.create(params[:name].to_s)
      flash[:notice] = "Bucket #{params[:name]} was created"
    else
      flash[:notice] = "Error, bucket #{params[:name]} already exists."
    end
    redirect_to :action => "index"
  end


end
