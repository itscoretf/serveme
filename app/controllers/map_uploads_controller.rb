# frozen_string_literal: true

class MapUploadsController < ApplicationController
  before_action :require_donator

  def new
    @map_upload = MapUpload.new
  end

  def create
    respond_to do |format|
      format.html do
        render :new, status: :unprocessable_entity if params[:map_upload].nil? && return

        @map_upload = MapUpload.new(params[:map_upload].permit(:file))
        @map_upload.user = current_user

        if @map_upload.save
          flash[:notice] = 'Map upload succeeded. It can take a few minutes for it to get synced to all servers.'
          redirect_to new_map_upload_path
        else
          render :new, status: :unprocessable_entity
        end
      end
    end
  end
end
