/**
 */
package fr.cea.nabla.ir.ir.impl;

import fr.cea.nabla.ir.ir.CArray;
import fr.cea.nabla.ir.ir.IrPackage;
import fr.cea.nabla.ir.ir.IrType;
import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.ecore.EClass;

import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>CArray</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.CArrayImpl#getPrimitive <em>Primitive</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.CArrayImpl#getSize <em>Size</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.CArrayImpl#isStatic <em>Static</em>}</li>
 * </ul>
 *
 * @generated
 */
public class CArrayImpl extends IrTypeImpl implements CArray {
	/**
	 * The cached value of the '{@link #getPrimitive() <em>Primitive</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getPrimitive()
	 * @generated
	 * @ordered
	 */
	protected IrType primitive;

	/**
	 * The default value of the '{@link #getSize() <em>Size</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getSize()
	 * @generated
	 * @ordered
	 */
	protected static final int SIZE_EDEFAULT = 0;

	/**
	 * The cached value of the '{@link #getSize() <em>Size</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getSize()
	 * @generated
	 * @ordered
	 */
	protected int size = SIZE_EDEFAULT;

	/**
	 * The default value of the '{@link #isStatic() <em>Static</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isStatic()
	 * @generated
	 * @ordered
	 */
	protected static final boolean STATIC_EDEFAULT = false;

	/**
	 * The cached value of the '{@link #isStatic() <em>Static</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isStatic()
	 * @generated
	 * @ordered
	 */
	protected boolean static_ = STATIC_EDEFAULT;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected CArrayImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return IrPackage.Literals.CARRAY;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public IrType getPrimitive() {
		if (primitive != null && primitive.eIsProxy()) {
			InternalEObject oldPrimitive = (InternalEObject)primitive;
			primitive = (IrType)eResolveProxy(oldPrimitive);
			if (primitive != oldPrimitive) {
				InternalEObject newPrimitive = (InternalEObject)primitive;
				NotificationChain msgs = oldPrimitive.eInverseRemove(this, EOPPOSITE_FEATURE_BASE - IrPackage.CARRAY__PRIMITIVE, null, null);
				if (newPrimitive.eInternalContainer() == null) {
					msgs = newPrimitive.eInverseAdd(this, EOPPOSITE_FEATURE_BASE - IrPackage.CARRAY__PRIMITIVE, null, msgs);
				}
				if (msgs != null) msgs.dispatch();
				if (eNotificationRequired())
					eNotify(new ENotificationImpl(this, Notification.RESOLVE, IrPackage.CARRAY__PRIMITIVE, oldPrimitive, primitive));
			}
		}
		return primitive;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public IrType basicGetPrimitive() {
		return primitive;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public NotificationChain basicSetPrimitive(IrType newPrimitive, NotificationChain msgs) {
		IrType oldPrimitive = primitive;
		primitive = newPrimitive;
		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, IrPackage.CARRAY__PRIMITIVE, oldPrimitive, newPrimitive);
			if (msgs == null) msgs = notification; else msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setPrimitive(IrType newPrimitive) {
		if (newPrimitive != primitive) {
			NotificationChain msgs = null;
			if (primitive != null)
				msgs = ((InternalEObject)primitive).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - IrPackage.CARRAY__PRIMITIVE, null, msgs);
			if (newPrimitive != null)
				msgs = ((InternalEObject)newPrimitive).eInverseAdd(this, EOPPOSITE_FEATURE_BASE - IrPackage.CARRAY__PRIMITIVE, null, msgs);
			msgs = basicSetPrimitive(newPrimitive, msgs);
			if (msgs != null) msgs.dispatch();
		}
		else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.CARRAY__PRIMITIVE, newPrimitive, newPrimitive));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public int getSize() {
		return size;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setSize(int newSize) {
		int oldSize = size;
		size = newSize;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.CARRAY__SIZE, oldSize, size));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean isStatic() {
		return static_;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setStatic(boolean newStatic) {
		boolean oldStatic = static_;
		static_ = newStatic;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.CARRAY__STATIC, oldStatic, static_));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
			case IrPackage.CARRAY__PRIMITIVE:
				return basicSetPrimitive(null, msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case IrPackage.CARRAY__PRIMITIVE:
				if (resolve) return getPrimitive();
				return basicGetPrimitive();
			case IrPackage.CARRAY__SIZE:
				return getSize();
			case IrPackage.CARRAY__STATIC:
				return isStatic();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case IrPackage.CARRAY__PRIMITIVE:
				setPrimitive((IrType)newValue);
				return;
			case IrPackage.CARRAY__SIZE:
				setSize((Integer)newValue);
				return;
			case IrPackage.CARRAY__STATIC:
				setStatic((Boolean)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case IrPackage.CARRAY__PRIMITIVE:
				setPrimitive((IrType)null);
				return;
			case IrPackage.CARRAY__SIZE:
				setSize(SIZE_EDEFAULT);
				return;
			case IrPackage.CARRAY__STATIC:
				setStatic(STATIC_EDEFAULT);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case IrPackage.CARRAY__PRIMITIVE:
				return primitive != null;
			case IrPackage.CARRAY__SIZE:
				return size != SIZE_EDEFAULT;
			case IrPackage.CARRAY__STATIC:
				return static_ != STATIC_EDEFAULT;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String toString() {
		if (eIsProxy()) return super.toString();

		StringBuilder result = new StringBuilder(super.toString());
		result.append(" (size: ");
		result.append(size);
		result.append(", static: ");
		result.append(static_);
		result.append(')');
		return result.toString();
	}

} //CArrayImpl
