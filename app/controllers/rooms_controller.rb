class RoomsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_room, only: %i[show edit update destroy]

  # GET /rooms
  def index
    @rooms = Room.all.order(created_at: :desc)
  end

  # GET /rooms/1
  def show
  end

  # GET /rooms/new
  def new
    @room = Room.new
  end

  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms
  def create
    @room = Room.new(room_params)

    respond_to do |format|
      if @room.save
        format.html { redirect_to @room, notice: "Espaço criado com sucesso." }
        format.json { render :show, status: :created, location: @room }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @room.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /rooms/1
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to @room, notice: "Espaço atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @room.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /rooms/1
  def destroy
    @room.destroy!

    respond_to do |format|
      format.html { redirect_to rooms_path, notice: "Espaço removido com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_room
    @room = Room.find(params.expect(:id))
  end

  def room_params
    params.expect(room: [ :name, :capacity, :capacity_auditorium, :capacity_u_shape, :capacity_classroom, :capacity_round_tables, :hourly_rate, :daily_rate, :description ])
  end
end
