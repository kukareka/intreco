class Interview < ApplicationRecord
  has_one :expert_token, -> { where(role: :expert) }, class_name: 'InterviewToken', dependent: :destroy
  has_one :candidate_token, -> { where(role: :candidate) }, class_name: 'InterviewToken', dependent: :destroy
end
