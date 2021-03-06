// =================================================================================================
//
//	CadetEngine Framework
//	Copyright 2012 Unwrong Ltd. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// Inspectable Priority range 50-99

package cadet2D.components.transforms
{
    import cadet.core.Component;
    import cadet.core.IComponentContainer;
    import cadet.events.ValidationEvent;
    import cadet.util.ComponentUtil;
    import cadet.util.deg2rad;
    import cadet.util.rad2deg;

    import core.events.PropertyChangeEvent;

    import flash.geom.Matrix;

    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Shape;

    [Cadet( inheritFromTemplate='false' )]
	public class Transform2D extends Component implements ITransform2D
	{
		protected var _x						:Number = 0;
		protected var _y						:Number = 0;
		protected var _scaleX					:Number = 1;
		protected var _scaleY					:Number = 1;
		// Rotation values are stored in degrees for ease of hand editing, then converted
		// to radians when passed to Starling DisplayObject
		protected var _rotation					:Number = 0;
        protected var _globalMatrix             :Matrix = new Matrix();
		
		protected var _displayObject			:DisplayObject;
        protected var _parentTransform          :Transform2D = null;

        public var dispatchEvents:Boolean = false; // Added as a speed optimisation

		protected static const TRANSFORM				:String = "transform";
		public static const PROPERTY_CHANGE_X			:String = "propertyChange_x";
		public static const PROPERTY_CHANGE_Y			:String = "propertyChange_y";
		public static const PROPERTY_CHANGE_SCALEX		:String = "propertyChange_scaleX";
		public static const PROPERTY_CHANGE_SCALEY		:String = "propertyChange_scaleY";
		public static const PROPERTY_CHANGE_ROTATION	:String = "propertyChange_rotation";

        public static function findParentTransform( parent:IComponentContainer ):Transform2D {
            var transform:Transform2D = null;

            while(parent != null) {
                transform = ComponentUtil.getChildOfType(parent, Transform2D);

                if(transform != null)
                    break;

                parent = parent.parentComponent;
            }

            return transform;
        }

        public function Transform2D( x:Number = 0, y:Number = 0, rotation:Number = 0, scaleX:Number = 1, scaleY:Number = 1 )
		{
			super( "Transform2D" );
			
			_displayObject = new Shape();
			this.x = x;
			this.y = y;
			this.rotation = rotation;
			this.scaleX = scaleX;
			this.scaleY = scaleY;
		}
		
		[Inspectable( priority="50" )]
		public function set x( value:Number ):void
		{
			if ( isNaN(value) ) {
				throw( new Error( "value is not a number" ) );
			}
			
			_x = value;
			invalidate(TRANSFORM);
			
			if (dispatchEvents)	{
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_X, null, value ) );
			}
		}
		public function get x():Number { return _x; }
		
		[Inspectable( priority="51" )]
		public function set y( value:Number ):void
		{
			if ( isNaN(value) ) {
				throw( new Error( "value is not a number" ) );
			}
		
			_y = value;
			invalidate(TRANSFORM);
			
			if (dispatchEvents) {
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_Y, null, value ) );
			}
		}
		public function get y():Number { return _y; }
		
		[Inspectable( priority="52" )]
		public function set scaleX( value:Number ):void
		{
			if ( isNaN(value) ) {
				throw( new Error( "value is not a number" ) );
			}
			
			_scaleX = value;
			invalidate(TRANSFORM);
			
			if (dispatchEvents) {
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_SCALEX, null, value ) );
			}
		}
		public function get scaleX():Number { return _scaleX; }
		
		[Inspectable( priority="53" )]
		public function set scaleY( value:Number ):void
		{
			if ( isNaN(value) ) {
				throw( new Error( "value is not a number" ) );
			}
			
			_scaleY = value;
			invalidate(TRANSFORM);
			
			if (dispatchEvents) {
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_SCALEY, null, value ) );
			}
		}
		public function get scaleY():Number { return _scaleY; }
		
		[Inspectable( priority="54", editor="Slider", min="0", max="360", snapInterval="1" ) ]
		public function set rotation( value:Number ):void
		{
			if ( isNaN(value) ) {
				throw( new Error( "value is not a number" ) );
			}
			
			_rotation = value;
			invalidate(TRANSFORM);
			
			if (dispatchEvents) {
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_ROTATION, null, value ) );
			}
		}
		public function get rotation():Number { return _rotation; }
		
		public function set matrix( value:Matrix ):void
		{
			_displayObject.transformationMatrix = value;
			_x = _displayObject.x;
			_y = _displayObject.y;
			_scaleX = _displayObject.scaleX;
			_scaleY = _displayObject.scaleY;
			_rotation = rad2deg(_displayObject.rotation);
			
			invalidate(TRANSFORM);
			
			if (dispatchEvents) {
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_X, null, _displayObject.x ) );
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_Y, null, _displayObject.y ) );
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_SCALEX, null, _displayObject.scaleX ) );
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_SCALEY, null, _displayObject.scaleY ) );
				dispatchEvent( new PropertyChangeEvent( PROPERTY_CHANGE_ROTATION, null, _displayObject.rotation ) );				
			}
		}
		public function get matrix():Matrix 
		{ 
			if (isInvalid(TRANSFORM)) {
				validateTransform();
			}
			
			return _displayObject.transformationMatrix;
		}

        public function get globalMatrix():Matrix
        {
            if (isInvalid(TRANSFORM)) {
                validateTransform();
            }

            return _globalMatrix;
        }

        [Serializable]
        public function set parentTransform(value:ITransform2D):void
        {
            cleanUpParentTransform();
            setupParentTransform(Transform2D(value));
        }
        public function get parentTransform():ITransform2D { return _parentTransform; }

        [Serializable(alias="matrix")]
		public function set serializedMatrix( value:String ):void
		{
			var split:Array = value.split( "," );
			matrix = new Matrix( split[0], split[1], split[2], split[3], split[4], split[5] );
		}
		
		public function get serializedMatrix():String 
		{ 
			var m:Matrix = matrix;
			return m.a + "," + m.b + "," + m.c + "," + m.d + "," + m.tx + "," + m.ty;
		}

        public function setupParentTransform( transform:Transform2D ):void
        {
            if(parentTransform != null)
                throw new Error("parentTransform already set, call cleanUpParentTransform() first");

            if(transform != null) {
                _parentTransform = transform;

                var container:DisplayObjectContainer = DisplayObjectContainer(_parentTransform._displayObject);
                container.addChild(_displayObject);

                invalidate(TRANSFORM);

                _parentTransform.addEventListener(ValidationEvent.INVALIDATE, onParentTransformInvalidated);
            }
        }

        public function cleanUpParentTransform():void
        {
            if(_parentTransform != null) {
                _parentTransform.removeEventListener(ValidationEvent.INVALIDATE, onParentTransformInvalidated);

                _displayObject.removeFromParent();
                _parentTransform = null;

                invalidate(TRANSFORM);
            }
        }

		override public function validateNow():void
		{
			if (isInvalid(TRANSFORM)) {
				validateTransform();
			}
			
			super.validateNow();
		}
		
		protected function validateTransform():void
		{
			_displayObject.x = _x;
			_displayObject.y = _y;
			_displayObject.scaleX = _scaleX;
			_displayObject.scaleY = _scaleY;
			_displayObject.rotation = deg2rad(_rotation);
            _displayObject.getTransformationMatrix(null, _globalMatrix);
		}

        override protected function addedToScene():void
        {
            // it's already set when deserializing
            if( _parentTransform == null) {
                var transform:Transform2D = findParentTransform(parentComponent.parentComponent);
                setupParentTransform(transform);
            }
        }

        override protected function removedFromScene():void
        {
            cleanUpParentTransform();
        }

        protected function onParentTransformInvalidated(event:ValidationEvent):void  { invalidate(TRANSFORM); }
    }
}
