class GigsController < ApplicationController
  before_action :set_gig, only: [:show, :edit, :update, :destroy, :availability]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :availability]

  # GET /gigs
  # GET /gigs.json
  def index

    @ip = request.remote_ip
    @location = request.location
    @city = @location.city.present? ? @location.city : 'Ogden'
    @state = @location.state.present? ? @location.state : 'UT'
    @range = params['range'].present? ? params['range'] : 100
    @gigs = []
    @profiles = Profile.near("#{@city}, #{@state}, US", @range).where(customer: true)
    @profiles.each do |profile|
      if profile.gigs.present?
        profile.gigs.each do |gig|
          @gigs << gig
        end
      end
    end

  end

  # GET /gigs/1
  # GET /gigs/1.json
  def show
    @gig = Gig.find_by id: params[:id]
    @profile = Profile.find_by id: @gig.profile_id
  end

  # GET /gigs/new
  def new
    @gig = Gig.new
  end

  # GET /gigs/1/edit
  def edit
  end

  # POST /gigs
  # POST /gigs.json
  def create
    @gig = Gig.new(gig_params)

    respond_to do |format|
      if @gig.save
        format.html { redirect_to @gig, notice: 'Gig was successfully created.' }
        format.json { render :show, status: :created, location: @gig }
      else
        format.html { render :new }
        format.json { render json: @gig.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    @ip = request.remote_ip
    @location = request.location
    @search = ''
    @city = @location.city.present? ? @location.city : 'Ogden'
    @state = @location.state.present? ? @location.state : 'UT'
    @range = params['range'].present? ? params['range'] : 100
    @gigs = []
    if params[:customer].present?
      @search = !params[:customer][:search].blank? ? params[:customer][:search] : ''
      @job = params[:customer][:job].present? ? params[:customer][:job].to_i : nil
    end

    @profiles = Profile.near("#{@city}, #{@state}, US", @range).where( customer: true )
    @profiles = @profiles.where( job_id: @job ) if @job != nil

    if @profiles.tagged_with(@search).length > 0
      @profiles = @profiles.tagged_with(@search)
    end
    @profiles.each do |profile|
      byebug
      if profile.gigs.present?
        profile.gigs.each do |gig|
          @gigs << gig if (gig.jobName.downcase.include? @search) || (gig.description.downcase.include? @search)
        end
      end
    end
  end

  # PATCH/PUT /gigs/1
  # PATCH/PUT /gigs/1.json
  def update
    respond_to do |format|
      if @gig.update(gig_params)
        format.html { redirect_to @gig, notice: 'Gig was successfully updated.' }
        format.json { render :show, status: :ok, location: @gig }
      else
        format.html { render :edit }
        format.json { render json: @gig.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gigs/1
  # DELETE /gigs/1.json
  def destroy
    @gig.destroy
    respond_to do |format|
      format.html { redirect_to gigs_url, notice: 'Gig was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  def availability
    if request.post?
      count = 0
      if params[:day].present?
        params[:day].each_with_index { |day,index|
          @availability = Availability.find_or_create_by(day_of_week: index, gig_id: @gig.id)
          availability_params = {
              day_of_week: index,
              earlyMorning: day.last[:earlyMorning].to_i,
              lateMorning: day.last[:lateMorning].to_i,
              earlyAfternoon: day.last[:earlyAfternoon].to_i,
              lateAfternoon: day.last[:lateAfternoon].to_i,
              earlyEvening: day.last[:earlyEvening].to_i,
              lateEvening: day.last[:lateEvening].to_i,
              overnight: day.last[:overnight].to_i,
              gig_id: @gig.id
          }
          @availability.update_attributes(availability_params)
          count += 1
        }
        if count == 7
          redirect_to edit_gig_path @gig.id
        end
      end

    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gig
      @gig = Gig.find(params[:id])
    end

    def set_user
      @user = User.find_by(id: current_user.id)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gig_params
      params.fetch(:gig, {})
    end
end
