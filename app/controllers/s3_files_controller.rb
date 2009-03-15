class S3FilesController < ApplicationController

  def index
  end
  
  def show
    @bucket = S3Bucket.find(params[:id])
    @file = S3File.find(params[:file], params[:id])
    @crumbs = [ 'Buckets', params[:id], params[:file]]
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
