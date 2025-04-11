const app = new Vue({
  el: '#app',
  data: {
    ui: false,
    cars: [],
    carTypes: [],
    colorOptions: [],
    shopName: "CAR DEALERSHIP",
    shopType: "car",
    testDrivePrice: 0,
    playerMoney: {
      cash: 0,
      bank: 0,
      dirtycash: 0
    },
    categories: [],
    searchQuery: '',
    searchTimeout: null,
    currentCategory: 'all',
    selectedCarIndex: null,
    notifications: [],
    showModal: false,
    modalData: {
      type: 'purchase'
    },
    rentDays: 3,
    showTestDriveConfirm: false,
    selectedPaymentMethod: 'cash',
    isScrollable: false,
    hasScrollLeft: false,
    hasScrollRight: false,
    loading: false,
    error: null,
    previousState: {
      searchQuery: '',
      currentCategory: 'all',
      selectedCarIndex: null,
      filteredCars: []
    },
    isSearching: false,
    cachedResults: new Map(),
    lastSearchTime: 0,
    safeList: [],
    initialized: false,
    selectedColor: "#FFFFFF",
    colorHue: 0,
    colorSaturation: 100,
    activeColorType: 'primary',
    vehicleRotation: 0,
    isDragging: false,
    lastMouseX: 0,
    startX: 0,
    startY: 0,
    vehicleHeading: 0,
    lastRotation: 0
  },
  computed: {
    filteredCars() {
      try {
        if (!this.initialized || !Array.isArray(this.safeList)) {
          return [];
        }

        let filtered = [...this.safeList];
        const searchTerm = (this.searchQuery || '').toLowerCase().trim();
        const cacheKey = `${this.currentCategory}-${searchTerm}`;

        if (this.cachedResults.has(cacheKey)) {
          return this.cachedResults.get(cacheKey);
        }

        if (this.currentCategory && this.currentCategory !== 'all') {
          filtered = filtered.filter(car => car && car.category === this.currentCategory);
        }
        
        if (searchTerm) {
          filtered = this.performOptimizedSearch(filtered, searchTerm);
        }

        if (filtered.length > 0) {
          this.cachedResults.set(cacheKey, filtered);
        }

        return filtered;
      } catch (error) {
        console.warn('Filter computation error:', error);
        return this.safeList || [];
      }
    },
    
    hasNoResults() {
      return Array.isArray(this.filteredCars) && this.filteredCars.length === 0;
    },
    
    selectedCar() {
      if (this.selectedCarIndex === null || !Array.isArray(this.filteredCars)) {
        return null;
      }
      
      if (this.selectedCarIndex >= 0 && this.selectedCarIndex < this.filteredCars.length) {
        return this.filteredCars[this.selectedCarIndex];
      }
      
      return null;
    }
  },
  watch: {
    cars: {
      immediate: true,
      handler(newCars) {
        if (Array.isArray(newCars)) {
          this.safeList = newCars.map((car, index) => ({
            ...car,
            _uid: `car_${index}_${Date.now()}`,
            _index: index,
            primaryColor: car.primaryColor || { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } },
            secondaryColor: car.secondaryColor || { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } },
            currentColor: '#FFFFFF'
          }));
        } else {
          this.safeList = [];
        }
        this.initialized = true;
      }
    },
    selectedCar: {
      immediate: true,
      deep: true,
      handler(car) {
        if (car) {
          if (!car.primaryColor || !car.primaryColor.hex) {
            this.$set(car, 'primaryColor', { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } });
          }
          if (!car.secondaryColor || !car.secondaryColor.hex) {
            this.$set(car, 'secondaryColor', { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } });
          }
          if (!car.currentColor || car.currentColor === '') {
            this.$set(car, 'currentColor', '#FFFFFF');
          }
        }
      }
    },
    searchQuery: {
      immediate: true,
      handler(newQuery) {
        if (!this.initialized) return;
        
        try {
          if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
          }
          
          this.handleSearch(newQuery);
        } catch (error) {
          console.warn('Search watch error:', error);
          this.resetToSafeState();
        }
      }
    },
    currentCategory: {
      immediate: true,
      handler(newCategory) {
        if (!this.initialized) return;
        
        try {
          this.handleSafeCategory(newCategory);
        } catch (error) {
          console.warn('Category watch error:', error);
          this.resetToSafeState();
        }
      }
    },
    filteredCars: {
      immediate: true,
      handler(newFiltered) {
        if (!this.initialized) return;
        
        try {
          this.updateSelectedIndex(newFiltered);
        } catch (error) {
          console.warn('Filtered cars watch error:', error);
          this.resetToSafeState();
        }
      }
    }
  },
  created() {
    window.addEventListener('message', this.handleEventMessage);
    document.addEventListener("keydown", this.onKeydown);

    this.selectedColor = "#FFFFFF";

    const originalSet = Vue.set;
    Vue.set = function(obj, key, value) {
      if (key && (
          key === 'currentColor' || 
          key === 'selectedColor' || 
          (typeof key === 'string' && key.toLowerCase().includes('color')) || 
          key === 'hex'
        )) {
        if (!value || value === '') {
          value = '#FFFFFF';
        }
      }
      return originalSet(obj, key, value);
    };
  },
  mounted() {
    if (this.filteredCars.length > 0) {
      this.selectedCarIndex = 0;
    }
    
    this.$nextTick(() => {
      this.checkScrollability();
      window.addEventListener('resize', this.checkScrollability);
    });

    document.addEventListener('mouseup', this.stopRotation);
    document.addEventListener('mousemove', this.rotateVehicle);

    document.querySelectorAll('input[type="color"]').forEach(input => {
      if (!input.value || input.value === '') {
        input.value = '#FFFFFF';
      }
    });

    window.addEventListener('message', (event) => {
      const item = event.data;
      if (item.action === 'CARSHOP' && item.open) {
        this.testDrivePrice = item.testDrivePrice || 250; 
      }
    });
  },
  methods: {
    formatPrice(price) {
      return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(price);
    },
    
    formatCategoryName(category) {
      if (!category) return '';
      return category.charAt(0).toUpperCase() + category.slice(1).toLowerCase();
    },
    
    changeCategory(category) {
      try {
        if (category === this.currentCategory) return;
        
        const previousCategory = this.currentCategory;
        this.currentCategory = category;
        
        this.cachedResults.clear();
        
        this.$nextTick(() => {
          const filtered = this.filteredCars;
          this.selectedCarIndex = filtered.length > 0 ? 0 : null;

          const container = this.$refs.categoriesContainer;
          const activeBtn = container?.querySelector('.cyber-btn-active');
          
          if (container && activeBtn) {
            const scrollLeft = activeBtn.offsetLeft - container.offsetWidth / 2 + activeBtn.offsetWidth / 2;
            container.scrollTo({ left: scrollLeft, behavior: 'smooth' });
          }
        });
      } catch (error) {
        this.currentCategory = previousCategory;
        this.handleError('This vehicle is out of stock');
      }
    },
    
    checkScrollability() {
      const container = this.$refs.categoriesContainer;
      if (container) {
        this.isScrollable = container.scrollWidth > container.clientWidth;
        this.checkScroll();
      }
    },
    
    checkScroll() {
      const container = this.$refs.categoriesContainer;
      if (container) {
        this.hasScrollLeft = container.scrollLeft > 0;
        this.hasScrollRight = container.scrollLeft + container.clientWidth < container.scrollWidth;
      }
    },
    
    scrollCategoriesLeft() {
      const container = this.$refs.categoriesContainer;
      if (container) {
        container.scrollBy({ left: -200, behavior: 'smooth' });
      }
    },
    
    scrollCategoriesRight() {
      const container = this.$refs.categoriesContainer;
      if (container) {
        container.scrollBy({ left: 200, behavior: 'smooth' });
      }
    },
    
    selectCar(index) {
      if (index === this.selectedCarIndex) return;

      this.selectedCarIndex = index;
      
      if (this.selectedCar && this.selectedCar.model) {
        this.initializeCarData(this.selectedCar);
        
        const primaryColor = this.selectedCar.primaryColor?.hex || '#FFFFFF';
        const secondaryColor = this.selectedCar.secondaryColor?.hex || '#FFFFFF';
        
        $.post('https://es-carshop/action', JSON.stringify({
          action: 'view-car',
          model: this.selectedCar.model,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor
        }))
        .fail((error) => {
          console.error('Vehicle display error:', error);
          this.addNotification('Error', 'Could not display vehicle. Please select another vehicle.', 'error');
        });
      } else {
        this.addNotification('Error', 'Invalid vehicle model.', 'error');
      }
    },
    
    purchaseCar() {
      if (!this.selectedCar) return;
      if (this.selectedCar.stock <= 0) {
        this.addNotification('STOK YOK', 'This vehicle is out of stock.', 'error');
        return;
      }

      if (this.showTestDriveConfirm) {
        this.showTestDriveConfirm = false;
      }
      
      this.showModal = true;
      this.selectedPaymentMethod = 'cash'; 
    },
    
    initTestDrive() {
      if (!this.selectedCar) return;
      if (this.selectedCar.stock <= 0) {
        this.addNotification('STOK YOK', 'This vehicle is out of stock.', 'error');
        return;
      }

      if (this.showModal) {
        this.showModal = false;
      }
      
      this.showTestDriveConfirm = true;
      this.selectedPaymentMethod = 'cash'; 
    },
    
    cancelTestDrive() {
      this.showTestDriveConfirm = false;
    },
    
    selectPaymentMethod(method) {
      this.selectedPaymentMethod = method;
    },
    
    confirmTransaction() {
      if (!this.selectedCar) return;
      
      let playerHasEnoughMoney = false;
      const price = this.selectedCar.price;
      
      if (this.selectedPaymentMethod === 'cash') {
        if (this.playerMoney.cash >= price) {
          playerHasEnoughMoney = true;
        } else {
          this.addNotification(
            'INSUFFICIENT FUNDS', 
            'You do not have enough cash to purchase this vehicle.', 
            'error'
          );
          return;
        }
      } else if (this.selectedPaymentMethod === 'bank') {
        if (this.playerMoney.bank >= price) {
          playerHasEnoughMoney = true;
        } else {
          this.addNotification(
            'INSUFFICIENT FUNDS', 
            'You do not have enough money in your bank account to purchase this vehicle.', 
            'error'
          );
          return;
        }
      }

      if (playerHasEnoughMoney) {
        $.post('https://es-carshop/purchase-car', JSON.stringify({
          model: this.selectedCar.model,
          name: this.selectedCar.name,
          price: this.selectedCar.price,
          paymentMethod: this.selectedPaymentMethod
        }));
        
        this.addNotification('PURCHASE SUCCESSFUL', `The ${this.selectedCar.brand} ${this.selectedCar.name} is now yours!`, 'success');
        
        this.showModal = false;
        this.ui = false;
      }
    },
    
    confirmTestDrive() {
      if (!this.selectedCar) return;
      
      let playerHasEnoughMoney = false;
      
      if (this.selectedPaymentMethod === 'cash') {
        if (this.playerMoney.cash >= this.testDrivePrice) {
          playerHasEnoughMoney = true;
        } else {
          this.addNotification(
            'INSUFFICIENT FUNDS', 
            'You do not have enough cash for the test drive deposit.', 
            'error'
          );
          return;
        }
      } else if (this.selectedPaymentMethod === 'bank') {
        if (this.playerMoney.bank >= this.testDrivePrice) {
          playerHasEnoughMoney = true;
        } else {
          this.addNotification(
            'INSUFFICIENT FUNDS', 
            'You do not have enough money in your bank account for the test drive deposit.', 
            'error'
          );
          return;
        }
      }

      if (playerHasEnoughMoney) {
        $.post('https://es-carshop/TestDrive', JSON.stringify({
          model: this.selectedCar.model,
          primaryColor: this.selectedCar.primaryColor?.hex || '#FFFFFF',
          secondaryColor: this.selectedCar.secondaryColor?.hex || '#FFFFFF',
          paymentMethod: this.selectedPaymentMethod,
          deposit: this.testDrivePrice
        }));
        this.addNotification('TEST DRIVE STARTED', `Starting test drive of ${this.selectedCar.brand} ${this.selectedCar.name}`, 'success');
        this.showTestDriveConfirm = false;
        this.Close();
      }
    },
    
    incrementRentDays() {
      if (this.rentDays < 30) {
        this.rentDays++;
      }
    },
    
    decrementRentDays() {
      if (this.rentDays > 1) {
        this.rentDays--;
      }
    },
    
    addNotification(title, message, type = 'info') {
      const notification = {
        title,
        message,
        type,
        id: Date.now()
      };
      
      this.notifications.unshift(notification);
      setTimeout(() => {
        const index = this.notifications.findIndex(n => n.id === notification.id);
        if (index !== -1) {
          const notifElement = document.querySelector(`[data-notification-id="${notification.id}"]`);
          if (notifElement) {
            notifElement.classList.add('fade-out');
            setTimeout(() => {
              this.notifications = this.notifications.filter(n => n.id !== notification.id);
            }, 500); 
          }
        }
      }, 4000);
    },
  
    handleEventMessage(event) {
      const item = event.data;
      
      if (item.action === "UPDATE-HUD") {
        if (item.cash !== undefined) {
          this.playerMoney = {
            cash: item.cash,
            bank: item.bank,
            dirtycash: item.dirtycash
          };
        }
      } else if (item.action === 'CARSHOP') {
        if (item.open) {
          this.ui = true;
          if (item.vehicles) {
            this.cars = item.vehicles;
          }
          if (item.types) {
            this.carTypes = item.types;
            this.categories = item.types;
          }
          if (item.colors) {
            this.colorOptions = item.colors;
          }
          if (item.shopName) {
            this.shopName = item.shopName;
          }
          if (item.shopType) {
            this.shopType = item.shopType;
          }
          
          this.checkScrollability();
        }
      } else if (item.action === 'NOTIFICATION') {
        this.addNotification(item.title, item.message, item.type);
      } else if (item.action === 'SELECT_FIRST_CAR') {
        if (this.categories && this.categories.length > 0) {
          this.currentCategory = this.categories[0].value;
          
          this.$nextTick(() => {
            if (this.filteredCars && this.filteredCars.length > 0) {
              this.selectCar(0);
            }
          });
        }
      }
    },
    
    Close() {
      this.ui = false;
      $.post('https://es-carshop/action', JSON.stringify({
        action: 'close'
      }));
    },
    
    Show() {
      this.ui = true;
    },
    
    onKeydown(event) {
      if (event.key === "Escape") {
        if (this.ui) {
          if (this.showTestDriveConfirm) {
            this.showTestDriveConfirm = false;
          } else if (this.showModal) {
            this.showModal = false;
          } else {
            this.Close();
          }
        } else {
          this.Show();
        }
      } else if (this.ui && (event.key === "ArrowLeft" || event.key === "ArrowRight")) {
        const container = this.$refs.categoriesContainer;
        if (container) {
          const scrollAmount = 150; 
          if (event.key === "ArrowLeft") {
            container.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
          } else {
            container.scrollBy({ left: scrollAmount, behavior: 'smooth' });
          }
          setTimeout(() => this.checkScroll(), 300);
        }
      } else if (this.ui && this.selectedCar) {
        if (event.key === "e" || event.key === "E") {
          $.post(`https://${GetParentResourceName()}/rotateright`);
        } else if (event.key === "q" || event.key === "Q") {
          $.post(`https://${GetParentResourceName()}/rotateleft`);
        }
      }
    },
    
    updateCategoryButtons() {
      this.$nextTick(() => {
        const buttons = document.querySelectorAll('.categories-container .cyber-btn');
        
        buttons.forEach(button => {
          if (button.textContent.trim().length > 12) {
            button.setAttribute('data-long-text', 'true');
          } else {
            button.removeAttribute('data-long-text');
          }
        });
      });
    },
    
    handleImageError(event) {
      try {
        const fallbackImage = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgMjAwIDIwMCI+CiAgPHJlY3Qgd2lkdGg9IjIwMCIgaGVpZ2h0PSIyMDAiIGZpbGw9IiMxYTFhMWEiLz4KICA8dGV4dCB4PSI1MCUiIHk9IjUwJSIgZm9udC1mYW1pbHk9IkFyaWFsIiBmb250LXNpemU9IjIwIiBmaWxsPSIjZmZmZmZmIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iLjNlbSI+Tm8gSW1hZ2U8L3RleHQ+Cjwvc3ZnPg==';
        event.target.src = fallbackImage;
        event.target.style.opacity = 1;
      } catch (error) {
        console.warn('Resim yükleme hatası:', error);
      }
    },
    
    handleError(errorMessage, state = null) {
      console.error('Error occurred:', errorMessage);
      this.error = errorMessage;
      this.isSearching = false;

      if (this.searchTimeout) {
        clearTimeout(this.searchTimeout);
      }

      const recoveryState = state || this.previousState;

      this.searchQuery = recoveryState.searchQuery;
      this.currentCategory = recoveryState.currentCategory;
      this.selectedCarIndex = recoveryState.selectedCarIndex;

      return recoveryState.filteredCars;
    },

    performOptimizedSearch(cars, searchTerm) {
      try {
        if (!Array.isArray(cars) || !searchTerm) return [];

        const searchParts = searchTerm.split(' ').filter(Boolean);
        
        return cars.filter(car => {
          if (!car) return false;
          
          const searchText = [
            car.name,
            car.brand,
            car.model,
            car.category
          ].filter(Boolean).join(' ').toLowerCase();

          return searchParts.every(part => searchText.includes(part));
        });
      } catch (error) {
        console.warn('Search error:', error);
        return [];
      }
    },

    handleSearch(value) {
      try {
        const now = Date.now();
        if (now - this.lastSearchTime < 100) return;
        this.lastSearchTime = now;

        if (this.searchTimeout) {
          clearTimeout(this.searchTimeout);
        }

        this.searchTimeout = setTimeout(() => {
          try {
            this.isSearching = true;
            this.searchQuery = value || '';

            this.$nextTick(() => {
              const filtered = this.filteredCars;
              this.selectedCarIndex = filtered.length > 0 ? 0 : null;
              this.isSearching = false;
            });
          } catch (error) {
            console.warn('Search timeout error:', error);
            this.resetToSafeState();
          }
        }, 200);

      } catch (error) {
        console.warn('Handle search error:', error);
        this.resetToSafeState();
      }
    },

    clearSearch() {
      try {
        if (this.searchTimeout) {
          clearTimeout(this.searchTimeout);
        }
        this.searchQuery = '';
        this.isSearching = false;
        this.selectedCarIndex = null;
        
        this.$nextTick(() => {
          const filtered = this.filteredCars;
          if (filtered.length > 0) {
            this.selectedCarIndex = 0;
          }
        });
      } catch (error) {
        console.warn('Clear search error:', error);
        this.resetToSafeState();
      }
    },

    handleSafeCategory(category) {
      try {
        if (category === this.currentCategory) return;
        
        this.currentCategory = category || 'all';
        this.cachedResults.clear();
        this.updateSelectedIndex(this.filteredCars);
        
        this.$nextTick(() => {
          const container = this.$refs.categoriesContainer;
          const activeBtn = container?.querySelector('.cyber-btn-active');
          
          if (container && activeBtn) {
            const containerRect = container.getBoundingClientRect();
            const buttonRect = activeBtn.getBoundingClientRect();
            const buttonCenter = buttonRect.left + buttonRect.width / 2;
            const containerCenter = containerRect.left + containerRect.width / 2;
            const offset = buttonCenter - containerCenter;
            container.scrollBy({ 
              left: offset, 
              behavior: 'smooth' 
            });
            
            setTimeout(() => this.checkScroll(), 300);
          }
        });
      } catch (error) {
        console.warn('Safe category error:', error);
        this.resetToSafeState();
      }
    },

    updateSelectedIndex(filteredList) {
      try {
        if (!Array.isArray(filteredList)) {
          this.selectedCarIndex = null;
          return;
        }

        if (filteredList.length > 0) {
          if (this.selectedCarIndex === null || this.selectedCarIndex >= filteredList.length) {
            this.selectedCarIndex = 0;
          }
        } else {
          this.selectedCarIndex = null;
        }
      } catch (error) {
        console.warn('Update index error:', error);
        this.selectedCarIndex = null;
      }
    },

    resetToSafeState() {
      try {
        this.searchQuery = '';
        this.currentCategory = 'all';
        this.selectedCarIndex = null;
        this.isSearching = false;
        this.cachedResults.clear();
        
        if (this.searchTimeout) {
          clearTimeout(this.searchTimeout);
        }

        if (Array.isArray(this.cars)) {
          this.safeList = this.cars.map((car, index) => ({
            ...car,
            _uid: `car_${index}_${Date.now()}`,
            _index: index,
            primaryColor: car.primaryColor || { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } },
            secondaryColor: car.secondaryColor || { hex: '#FFFFFF', rgb: { r: 255, g: 255, b: 255 } },
            currentColor: '#FFFFFF'
          }));
        } else {
          this.safeList = [];
        }
      } catch (error) {
        console.warn('Reset state error:', error);
        this.safeList = [];
        this.selectedCarIndex = null;
      }
    },
    
    updateCarColor(event, car) {
      try {
        const newColor = (event?.target?.value) || '#FFFFFF';
        
        if (!car) return;

        if (this.activeColorType === 'primary' || !this.activeColorType) {
          if (car.primaryColor) {
            car.primaryColor.hex = newColor;
            car.primaryColor.rgb = this.hexToRgb(newColor);
          } else {
            car.primaryColor = { 
              hex: newColor,
              rgb: this.hexToRgb(newColor)
            };
          }
          car.selectedColor = newColor;
          car.currentColor = newColor;
        } else if (this.activeColorType === 'secondary') {
          if (car.secondaryColor) {
            car.secondaryColor.hex = newColor;
            car.secondaryColor.rgb = this.hexToRgb(newColor);
          } else {
            car.secondaryColor = {
              hex: newColor,
              rgb: this.hexToRgb(newColor)
            };
          }
          car.selectedColor = newColor;
          car.currentColor = newColor;
        }

        const carToUpdate = this.selectedCar && car._uid === this.selectedCar._uid ? 
                            this.selectedCar : car;

        if (carToUpdate && carToUpdate.model) {
          const primaryColor = carToUpdate.primaryColor?.hex || '#FFFFFF';
          const secondaryColor = carToUpdate.secondaryColor?.hex || '#FFFFFF';

          $.post('https://es-carshop/update-car-color', JSON.stringify({
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
          }));
        }
      } catch (error) {
        console.log('Renk güncelleme hatası:', error);
      }
    },
    
    saveCarColor(car, type) {
      if (!car) return;
      
      this.activeColorType = type;
      
      if (type === 'primary') {
        car.currentColor = car.primaryColor?.hex || '#FFFFFF';
      } else if (type === 'secondary') {
        car.currentColor = car.secondaryColor?.hex || '#FFFFFF';
      }

      if (car.model) {
        const primaryColor = car.primaryColor?.hex || '#FFFFFF';
        const secondaryColor = car.secondaryColor?.hex || '#FFFFFF';

        $.post('https://es-carshop/update-car-color', JSON.stringify({
          primaryColor: primaryColor,
          secondaryColor: secondaryColor
        }));
      }
    },
    
    applyCarColor(car) {
      if (!car) return;
      
      const selectedColor = car.selectedColor || '#FFFFFF';
      
      if (this.activeColorType === 'primary' || !this.activeColorType) {
        if (car.primaryColor) {
          car.primaryColor.hex = selectedColor;
          car.primaryColor.rgb = this.hexToRgb(selectedColor);
        } else {
          car.primaryColor = {
            hex: selectedColor,
            rgb: this.hexToRgb(selectedColor)
          };
        }
      } else if (this.activeColorType === 'secondary') {
        if (car.secondaryColor) {
          car.secondaryColor.hex = selectedColor;
          car.secondaryColor.rgb = this.hexToRgb(selectedColor);
        } else {
          car.secondaryColor = {
            hex: selectedColor,
            rgb: this.hexToRgb(selectedColor)
          };
        }
      }

      if (car.model) {
        $.post('https://es-carshop/update-car-color', JSON.stringify({
          primaryColor: car.primaryColor?.hex || '#FFFFFF',
          secondaryColor: car.secondaryColor?.hex || '#FFFFFF'
        }));
      }
    },
    
    hexToRgb(hex) {
      hex = hex.replace(/^#/, '');
      const bigint = parseInt(hex, 16);
      const r = (bigint >> 16) & 255;
      const g = (bigint >> 8) & 255;
      const b = bigint & 255;
      
      return { r, g, b };
    },
    
    calculateHue(r, g, b) {
      r /= 255;
      g /= 255;
      b /= 255;
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      let h;

      if (max === min) {
        h = 0;
      } else {
        const d = max - min;
        switch (max) {
          case r: h = (g - b) / d + (g < b ? 6 : 0); break;
          case g: h = (b - r) / d + 2; break;
          case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
      }

      return h * 360;
    },

    calculateSaturation(r, g, b) {
      r /= 255;
      g /= 255;
      b /= 255;
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      const l = (max + min) / 2;
      let s;

      if (max === min) {
        s = 0;
      } else {
        const d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      }

      return s * 100;
    },

    initializeCarData(car) {
      if (!car) return;
      
      if (!car.primaryColor || !car.primaryColor.hex) {
        car.primaryColor = { 
          hex: '#FFFFFF', 
          rgb: { r: 255, g: 255, b: 255 } 
        };
      }
      
      if (!car.secondaryColor || !car.secondaryColor.hex) {
        car.secondaryColor = { 
          hex: '#FFFFFF', 
          rgb: { r: 255, g: 255, b: 255 } 
        };
      }
      
      if (this.activeColorType === 'primary' || !this.activeColorType) {
        car.currentColor = car.primaryColor.hex;
      } else {
        car.currentColor = car.secondaryColor.hex;
      }
      
      if (car.model) {
        $.post('https://es-carshop/action', JSON.stringify({
          action: 'view-car',
          model: car.model,
          primaryColor: car.primaryColor.hex,
          secondaryColor: car.secondaryColor.hex
        }));
      }
    },

    startRotation(event) {
      if (event.button === 0) { 
        this.isDragging = true;
        this.startX = event.clientX;
        this.startY = event.clientY;
        this.lastRotation = this.vehicleRotation;
        document.body.style.cursor = "move";
        event.preventDefault();
      }
    },
    
    rotateVehicle(event) {
      if (!this.isDragging) return;
      const sensitivity = 0.5; 
      const deltaX = event.clientX - this.startX;
      const newRotation = (this.vehicleRotation + deltaX * sensitivity) % 360;
      this.vehicleRotation = newRotation;
      fetch(`https://${GetParentResourceName()}/rotateVehicle`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ heading: newRotation })
      });
    },
    
    stopRotation() {
      this.isDragging = false;
      document.body.style.cursor = '';
      if (this.selectedCar && this.selectedCar.model) {
        $.post('https://es-carshop/action', JSON.stringify({
          action: 'rotate-car',
          model: this.selectedCar.model,
          rotation: this.vehicleRotation
        }));
      }
    },
  },
  beforeDestroy() {
    window.removeEventListener('message', this.handleEventMessage);
    document.removeEventListener("keydown", this.onKeydown);
    window.removeEventListener('resize', this.checkScrollability);
    document.removeEventListener('mouseup', this.stopRotation);
    document.removeEventListener('mousemove', this.rotateVehicle);
    
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
    this.cachedResults.clear();
  }
});