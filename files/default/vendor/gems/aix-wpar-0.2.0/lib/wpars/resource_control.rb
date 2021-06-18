module WPAR
  class ResourceControl
    attr_reader :name, :state, :active, :rset
    attr_reader :procvirtmem, :totalvirtmem, :totalprocesses
    attr_reader :totalptys, :totallargepages, :pct_msgids, :pct_semids
    attr_reader :pct_pinmem, :totalthreads, :pct_shmids
    attr_accessor :shares_cpu, :cpu, :shares_memory, :memory

    def initialize(params)
      @command = params[:command]
      @name = params[:name]
      @state = params[:state]
      @active = params[:active]
      @rset = params[:rset]
      @shares_cpu = params[:shares_cpu]
      @cpu = params[:cpu]
      @shares_memory = params[:shares_memory]
      @memory = params[:memory]
      @procvirtmem = params[:procvirtmem]
      @totalvirtmem = params[:totalvirtmem]
      @totalprocesses = params[:totalprocesses]
      @totalptys = params[:totalptys]
      @totallargepages = params[:totallargepages]
      @pct_msgids = params[:pct_msgids]
      @pct_semids = params[:pct_semids]
      @pct_pinmem = params[:pct_pinmem]
      @totalthreads = params[:totalthreads]
      @pct_shmids = params[:pct_shmids]
    end

    def empty?
      wpar_attributes.all? { |k, _v| send(k).nil? }
    end

    def wpar_attributes
      attrs = ResourceControl.instance_methods(false) - [:name, :command, :state, :empty?, :wpar_attributes ]
      attrs - attrs.grep(/=$/)
    end
  end
end
