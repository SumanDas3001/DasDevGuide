class BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :edit, :update, :destroy, :toggle_status, :favorite_unfavorite_blog]
  before_action :set_sidebar_topics, except: [:create, :update, :destroy, :toggle_status, :favorite_unfavorite_blog]
  layout "blog"
  access all: [:show, :index], user: {except: [:destroy, :new, :create, :edit, :update, :toggle_status]}, site_admin: :all

  def index
    if logged_in?(:site_admin)
      @blogs = Blog.recent.page(params[:page]).paginate(:page => params[:page], :per_page => 10)
    else
      @blogs = Blog.published.recent.page(params[:page]).paginate(:page => params[:page], :per_page => 10)
    end
    @blogs = @blogs.search(params[:search]).page(params[:page]).paginate(:page => params[:page], :per_page => 10) if params[:search].present?
    @page_title = "DasDevGuide Blog"
  end

  def show
    if logged_in?(:site_admin) || @blog.published?
      @blog = Blog.includes(:comments).friendly.find(params[:id])
      @comment = Comment.new
      
      @page_title = @blog.title
      @seo_keywords = @blog.body
      topic = Topic.find_topic_by_id(@blog.topic_id)
      @latest_blogs = topic&.blogs.published.find_latest_blog(@blog.id)
    else
      redirect_to blogs_path, notice: "You are not authorized to access this page"
    end
  end

  def new
    @blog = Blog.new
  end

  def edit
  end

  def create
    @blog = Blog.new(blog_params)

    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: 'Blog was successfully created.' }
        format.json { render :show, status: :created, location: @blog }
      else
        format.html { render :new }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to @blog, notice: 'Blog was successfully updated.' }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @blog.destroy
    respond_to do |format|
      format.html { redirect_to blogs_url, notice: 'Blog was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def toggle_status
    if @blog.draft?
      @blog.published!
    elsif @blog.published?
      @blog.draft!
    end

    redirect_to blogs_path
  end

  def favorite_unfavorite_blog
    if !current_user.is_a?(GuestUser) && (logged_in?(:site_admin) || logged_in?(:user))
      favourite = UserFavoriteBlog.find_or_create_by(user_id: current_user.id, blog_id: @blog.id) rescue nil
      if favourite.present?
        if favourite.is_favorited 
          favourite.update(is_favorited: false)
        else
          favourite.update(is_favorited: true)
        end
      end
      redirect_to blog_path
    else
      redirect_to blog_path, alert: 'You need to login to continue.'
    end
  end

  private

  def set_blog
    @blog = Blog.friendly.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :body, :topic_id, :status, :image)
  end

  def set_sidebar_topics
    @side_bar_topics = Topic.with_blogs
  end
end
