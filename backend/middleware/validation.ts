import { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';

export const handleValidationErrors = (req: Request, res: Response, next: NextFunction) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation errors',
      errors: errors.array()
    });
  }
  next();
};

// Validaciones para usuarios
export const validateUserRegistration = [
  body('username')
    .isLength({ min: 3, max: 20 })
    .withMessage('Username must be between 3 and 20 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  
  body('firstName')
    .isLength({ min: 1, max: 50 })
    .withMessage('First name must be between 1 and 50 characters')
    .trim(),
  
  body('lastName')
    .isLength({ min: 1, max: 50 })
    .withMessage('Last name must be between 1 and 50 characters')
    .trim(),
  
  handleValidationErrors
];

export const validateUserLogin = [
  body('emailOrUsername')
    .notEmpty()
    .withMessage('Email or username is required'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  
  handleValidationErrors
];

// Validaciones para juegos
export const validateGameCreation = [
  body('name')
    .isLength({ min: 1, max: 100 })
    .withMessage('Game name must be between 1 and 100 characters')
    .trim(),
  
  body('startDate')
    .isISO8601()
    .withMessage('Start date must be a valid date'),
  
  body('maxLives')
    .isInt({ min: 1, max: 10 })
    .withMessage('Max lives must be between 1 and 10'),
  
  body('totalWeeks')
    .isInt({ min: 1 })
    .withMessage('Total weeks must be at least 1'),
  
  handleValidationErrors
];

// Validaciones para predicciones
export const validatePrediction = [
  body('week')
    .isInt({ min: 1 })
    .withMessage('Week must be a positive integer'),
  
  body('matchId')
    .notEmpty()
    .withMessage('Match ID is required'),
  
  body('selectedTeam')
    .isIn(['home', 'visitor', 'draw'])
    .withMessage('Selected team must be either "home", "visitor", or "draw"'),
  
  handleValidationErrors
];

// Validaciones para resultados de partidos
export const validateMatchResult = [
  body('homeScore')
    .isInt({ min: 0 })
    .withMessage('Home score must be a non-negative integer'),
  
  body('visitorScore')
    .isInt({ min: 0 })
    .withMessage('Visitor score must be a non-negative integer'),
  
  handleValidationErrors
];
